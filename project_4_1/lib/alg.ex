defmodule Alg do
  def bin2hex(bin) do
    Base.encode16(bin)
  end

  def hex2bin(hex) do
    Base.decode16!(hex)
  end

  def nil2str(list, out_list) do
    if list != [] do
      out_list =
        if hd(list) == nil do
          out_list ++ ["nil"]
        else
          out_list ++ [hd(list)]
        end
      nil2str(tl(list), out_list)
    else
      out_list
    end
  end

  def hashStruct(alg, object, num_rounds) do
    if num_rounds > 0 do
      vlist = Map.values(Map.from_struct(object))
      vlist = nil2str(vlist, []) # :crypto.hash cannot hash nil, so we have to convert all nil to "nil".
      res = :crypto.hash(alg, vlist) |> Base.encode16
      hashString(alg, res, num_rounds-1)
    else
      IO.puts "The number of hash rounds cannot be zero."
      nil
    end
  end

  def hashString(alg, string, num_rounds) do
    if num_rounds > 0 do
      res = :crypto.hash(alg, string) |> Base.encode16
      hashString(alg, res, num_rounds-1)
    else
      string
    end
  end

  def hashTransaction(transaction) do
    hashStruct(:sha256, transaction, 2)
  end

  def hashBlock(block) do # block hash is created by hashing block header twice.
    hashStruct(:sha256, block.header, 2)
  end

  def generateMerkleRoot(transactions) do
    nil
  end

  def generateKeyPair() do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    {Base.encode16(public_key), Base.encode16(private_key)}
  end

  def generateSignature(private_key, message) do
    private_key = hex2bin(private_key)
    :crypto.sign(:ecdsa, :sha256, message, [private_key, :secp256k1]) |> Base.encode16
  end

  def verifySignature(signature, public_key, message) do
    public_key = hex2bin(public_key)
    signature = hex2bin(signature)
    :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, :secp256k1])
  end

  def signTransaction(sender_private_key, prev_trans_hash, receiver_public_key) do
    hash = hashString(:sha256, prev_trans_hash<>receiver_public_key, 2)
    generateSignature(sender_private_key, hash)
  end

  def verifyTransaction(signature, sender_public_key, prev_trans_hash, receiver_public_key) do
    hash = hashString(:sha256, prev_trans_hash<>receiver_public_key, 2)
    verifySignature(signature, sender_public_key, hash)
  end

  def generateTransaction(sender_hash, receiver_hash, trans_amount, trans_fee, blockchain_pid, mode \\ 1) do
    # blockchain_pid is the PID of blockchain GenServer of current node
    # Each node uses a GenServer to manage its local blockchain copy
    tail_block = getTailBlock(blockchain_pid)
    {final_inputs_amount, final_inputs} = generateTransInputs(sender_hash, 0, [], trans_amount, trans_fee, tail_block, blockchain_pid)
    if mode == 1 and final_inputs_amount < trans_amount + trans_fee do
      IO.puts "You have no enough balance for this transaction!"
      nil
    else
      actual_output = %Transaction.Output{receiver: receiver_hash, value: trans_amount, is_spent: false}
      change_output = %Transaction.Output{receiver: sender_hash, value: final_inputs_amount - trans_amount - trans_fee, is_spent: false}
      trans_fee_output = %Transaction.Output{receiver: "", value: trans_fee, is_spent: false}
      %Transaction{sender: sender_hash, receiver: receiver_hash, num_inputs: length(final_inputs), inputs: final_inputs, num_outputs: 3, outputs: [actual_output, change_output, trans_fee_output], trans_fee: trans_fee, signature: ""}
    end
  end

  def generateTransInputs(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, tail_block, blockchain_pid) do
    if tail_block != nil and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs, then continue
      {cur_inputs_amount, cur_inputs} = generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, tail_block, 0)
      prev_block = getPrevBlock(tail_block, blockchain_pid)
      generateTransInputs(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, prev_block, blockchain_pid)
    else
      {cur_inputs_amount, cur_inputs}
    end
  end

  def generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, block, trans_index) do
    if trans_index < block.num_trans and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs and not yet arrived end of current block, then continue
      cur_trans = Enum.at(block.trans, trans_index)
      {cur_inputs_amount, cur_inputs} = generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, cur_trans, 0)
      generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, block, trans_index + 1)
    else
      {cur_inputs_amount, cur_inputs}
    end
  end

  def generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index) do
    if output_index < transaction.num_outputs and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs and not yet arrived end of current transaction, then continue
      cur_output = Enum.at(transaction.outputs, output_index)
      if cur_output.receiver == sender_hash do # if this output belongs to sender, sender can use it.
        new_input = %Transaction.Input{prev_trans_hash: hashTransaction(transaction), prev_output_index: output_index}
        cur_inputs = cur_inputs ++ [new_input]
        cur_inputs_amount = cur_inputs_amount + cur_output.value
        generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index + 1)
      else # sender cannot use it. we just skip it.
        generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index + 1)
      end
    else
      {cur_inputs_amount, cur_inputs}
    end
  end

  def getPrevBlock(blockchain_pid, cur_block) do
    #prev_block = GenServer.call(blockchain_pid, {:getBlock, cur_block.prev_hash})
    prev_block = getBlock(blockchain_pid, cur_block.header.prev_hash)
    prev_block
  end

  def getTailBlock(blockchain_pid) do
    GenServer.call(blockchain_pid, :getTailBlock)
  end

  def getBlock(blockchain_pid, block_hash) do
    GenServer.call(blockchain_pid, {:getBlock, block_hash})
  end

  def generateBlock(blockchain_pid, transactions, diff_target, nonce) do
    tail_block = getTailBlock(blockchain_pid)
    prev_hash =
      if tail_block == nil do
        ""
      else
        hashBlock(tail_block)
      end
    merkle_root = generateMerkleRoot(transactions)
    timestamp = nil # TODO: get current timestamp here
    block_header = %Block.Header{prev_hash: prev_hash, merkle_root: merkle_root, timestamp: timestamp, diff_target: diff_target, nonce: nonce}
    block = %Block{header: block_header, num_trans: length(transactions), trans: transactions}
    block
  end

  def appendBlock(blockchain_pid, block) do
    GenServer.call(blockchain_pid, {:appendBlock, block})
  end

  def printObject(object) do
    IO.puts inspect Map.from_struct(object)
  end

  def printBlockChain(blockchain_pid) do
    tail_block = getTailBlock(blockchain_pid)
    printBlockChainHelper(blockchain_pid, tail_block)
  end

  def printBlockChainHelper(blockchain_pid, cur_block) do
    if cur_block != nil do
      printObject(cur_block)
      printBlockChainHelper(blockchain_pid, getPrevBlock(blockchain_pid, cur_block))
    end
  end

  def getBalance(blockchain_pid, owner) do
    tail_block = getTailBlock(blockchain_pid)
    getBalanceHelper(blockchain_pid, owner, tail_block, 0)
  end

  def getBalanceHelper(blockchain_pid, owner, cur_block, balance) do
    if cur_block != nil do
      balance = balance + getBalanceInOneBlock(owner, cur_block)
      getBalanceHelper(blockchain_pid, owner, getPrevBlock(blockchain_pid, cur_block), balance)
    else
      balance
    end
  end

  def getBalanceInOneBlock(owner, block) do
    getBalanceInTransList(owner, block.trans, 0)
  end

  def getBalanceInTransList(owner, trans_list, balance) do
    if trans_list != [] do
      balance = balance + getBalanceInOneTrans(owner, hd(trans_list))
      getBalanceInTransList(owner, tl(trans_list), balance)
    else
      balance
    end
  end

  def getBalanceInOneTrans(owner, trans) do
    getBalanceInOutputs(owner, trans.outputs, 0)
  end

  def getBalanceInOutputs(owner, outputs, balance) do
    if outputs != [] do
      balance =
        if hd(outputs).receiver == owner do
          balance + hd(outputs).value
        else
          balance
        end
      getBalanceInOutputs(owner, tl(outputs), balance)
    else
      balance
    end
  end
end


