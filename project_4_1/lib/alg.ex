defmodule Alg do
  def bin2hex(bin) do
    Base.encode16(bin)
  end

  def hex2bin(hex) do
    Base.decode16!(hex)
  end

  """
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
  """

  def all2str(list, out_list) do
    if list != [] do
      out_list =
        if !String.valid?(hd(list)) do # if head of list is not a string
          out_list ++ [inspect(hd(list))] # convert it to a string
        else
          out_list ++ [hd(list)]
        end
      all2str(tl(list), out_list)
    else
      out_list
    end
  end

  def hashStruct(alg, object, num_rounds) do
    if num_rounds > 0 do
      vlist = Map.values(Map.from_struct(object))
      vlist = all2str(vlist, []) # :crypto.hash cannot hash non-string elements, so we have to convert all elements to strings.
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

  def getAllTransFee(transactions, res) do
    if transactions != [] do
      res = res + Enum.at(hd(transactions).outputs, 2) # outputs[2] is the transaction fee
      getAllTransFee(tl(transactions), res)
    else
      res
    end
  end

  def generateFirstTransaction(miner_hash, reward, normal_trans, blockchain_pid) do
    all_trans_fee = getAllTransFee(normal_trans, 0)
    actual_output = %Transaction.Output{receiver: miner_hash, value: reward + all_trans_fee, is_spent: false}
    %Transaction{sender: "", receiver: miner_hash, num_inputs: 0, inputs: [], num_outputs: 1, outputs: [actual_output], trans_fee: 0, signature: ""}
  end

  def generateTransaction(sender_hash, receiver_hash, trans_amount, trans_fee, blockchain_pid) do
    # blockchain_pid is the PID of blockchain GenServer of current node
    # Each node uses a GenServer to manage its local blockchain copy
    tail_block = getTailBlock(blockchain_pid)
    {final_inputs_amount, final_inputs} = generateTransInputs(sender_hash, 0, [], trans_amount, trans_fee, tail_block, blockchain_pid, MapSet.new())
    if final_inputs_amount < trans_amount + trans_fee do
      IO.puts "You have no enough balance for this transaction!"
      nil
    else
      actual_output = %Transaction.Output{receiver: receiver_hash, value: trans_amount, is_spent: false}
      change_output = %Transaction.Output{receiver: sender_hash, value: final_inputs_amount - trans_amount - trans_fee, is_spent: false}
      trans_fee_output = %Transaction.Output{receiver: "", value: trans_fee, is_spent: false}
      %Transaction{sender: sender_hash, receiver: receiver_hash, num_inputs: length(final_inputs), inputs: final_inputs, num_outputs: 3, outputs: [actual_output, change_output, trans_fee_output], trans_fee: trans_fee, signature: ""}
    end
  end

  def generateTransInputs(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, tail_block, blockchain_pid, input_src) do
    if tail_block != nil and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs, then continue
      {cur_inputs_amount, cur_inputs, input_src} = generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, tail_block, 0, input_src)
      prev_block = getPrevBlock(tail_block, blockchain_pid)
      generateTransInputs(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, prev_block, blockchain_pid, input_src)
    else
      {cur_inputs_amount, cur_inputs}
    end
  end

  def generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, block, trans_index, input_src) do
    if trans_index < block.num_trans and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs and not yet arrived end of current block, then continue
      cur_trans = Enum.at(block.trans, trans_index)
      {cur_inputs_amount, cur_inputs, input_src} = generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, cur_trans, 0, input_src)
      generateTransInputsInOneBlock(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, block, trans_index + 1, input_src)
    else
      {cur_inputs_amount, cur_inputs, input_src}
    end
  end

  def generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index, input_src) do
    # input_src is the sources of inputs, that is, the previous outputs. Here it is the same stuff with "inputs_after_it" in isSpentOutput().
    if output_index < transaction.num_outputs and cur_inputs_amount < trans_amount + trans_fee do # no enough inputs and not yet arrived end of current transaction, then continue
      cur_output = Enum.at(transaction.outputs, output_index)
      if cur_output.receiver == sender_hash and !isSpentOutput(transaction, output_index, input_src) do # if this output belongs to sender and has NOT been spent, sender can use it.
        input_src = MapSet.put(input_src, {hashTransaction(transaction), output_index})
        new_input = %Transaction.Input{prev_trans_hash: hashTransaction(transaction), prev_output_index: output_index}
        cur_inputs = cur_inputs ++ [new_input]
        cur_inputs_amount = cur_inputs_amount + cur_output.value
        generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index + 1, input_src)
      else # sender cannot use it. we just skip it.
        generateTransInputsInOneTransaction(sender_hash, cur_inputs_amount, cur_inputs, trans_amount, trans_fee, transaction, output_index + 1, input_src)
      end
    else
      {cur_inputs_amount, cur_inputs, input_src}
    end
  end

  def isSpentOutput(transaction, output_index, inputs_after_it) do # only need to check among the inputs after this output
    # inputs_after_it is a MapSet. Each element is a tuple, {previous transaction hash, output index}.
    MapSet.member?(inputs_after_it, {hashTransaction(transaction), output_index})
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

  def generateBlock(blockchain_pid, transactions, diff_target, nonce, miner_hash, reward) do
    tail_block = getTailBlock(blockchain_pid)
    #printObject(tail_block)
    #IO.puts "A"
    prev_hash =
      if tail_block == nil do
        ""
      else
        hashBlock(tail_block)
      end
    first_trans = generateFirstTransaction(miner_hash, reward, transactions, blockchain_pid)
    transactions = [first_trans] ++ transactions
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
      #IO.puts "Here"
      printBlockChainHelper(blockchain_pid, getPrevBlock(blockchain_pid, cur_block))
    end
  end

  """
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
  """

  def getBalance(owner, tail_block, blockchain_pid, input_src, balance) do
    if tail_block != nil do # not yet arrived at head of the blockchain, then continue
      {balance, input_src} = getBalanceInOneBlock(owner, tail_block, 0, input_src, balance)
      prev_block = getPrevBlock(tail_block, blockchain_pid)
      getBalance(owner, prev_block, blockchain_pid, input_src, balance)
    else
      balance
    end
  end

  def getBalanceInOneBlock(owner, block, trans_index, input_src, balance) do
    if trans_index < block.num_trans do # not yet arrived end of current block, then continue
      cur_trans = Enum.at(block.trans, trans_index)
      {balance, input_src} = getBalanceInOneTransaction(owner, cur_trans, 0, input_src, balance)
      getBalanceInOneBlock(owner, block, trans_index + 1, input_src, balance)
    else
      {balance, input_src}
    end
  end

  def getBalanceInOneTransaction(owner, transaction, output_index, input_src, balance) do
    # input_src is the sources of inputs, that is, the previous outputs. Here it is the same stuff with "inputs_after_it" in isSpentOutput().
    if output_index < transaction.num_outputs do # not yet arrived end of current transaction, then continue
      cur_output = Enum.at(transaction.outputs, output_index)
      if cur_output.receiver == owner and !isSpentOutput(transaction, output_index, input_src) do # if this output belongs to this account owner and has NOT been spent, it will be counted into balance.
        input_src = MapSet.put(input_src, {hashTransaction(transaction), output_index})
        balance = balance + cur_output.value
        getBalanceInOneTransaction(owner, transaction, output_index + 1, input_src, balance)
      else # This output cannot be counted into balance, so we just skip it.
        getBalanceInOneTransaction(owner, transaction, output_index + 1, input_src, balance)
      end
    else
      {balance, input_src}
    end
  end

  """
  def getBalanceInOutputs(balance, owner, transaction, outputs, output_index, input_src) do
    # balance: final result
    # owner: owner of the balance
    # transaction: the transaction to which the outputs belong
    # outputs: list of outputs inside the transaction
    # input_src: the source outputs of existed inputs
    #if outputs != [] do
    if output_index < length(outputs) do
      #balance =
        #if hd(outputs).receiver == owner and !isSpentOutput()do
      if Enum.at(outputs, output_index).receiver == owner and !isSpentOutput(transaction, output_index, input_src) do
        #input_src = MapSet.put(input_src, {hashTransaction(transaction), output_index})
        balance = balance + Enum.at(outputs, output_index).value
        getBalanceInOutputs(balance, owner, transaction, outputs, output_index + 1, input_src)
      else
        getBalanceInOutputs(balance, owner, transaction, outputs, output_index + 1, input_src)
      end
    else
      balance
    end
  end
  """
end


