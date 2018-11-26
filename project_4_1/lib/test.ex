defmodule Test do
  def testAlg() do
    Test.Alg.testHashTransaction()
    Test.Alg.testHashBlock()
    Test.Alg.testSignAndVerify()
    Test.Alg.testSignAndVerifyTransaction()
    Test.Alg.testGenerateFirstTransaction()
    Test.Alg.testGenerateTransaction()
    Test.Alg.testGenerateBlock()
    Test.Alg.testAppendBlock()
    Test.Alg.testGetBalance()
  end

  def testXXX() do
    # TODO
  end
end

defmodule Test.Alg do
  @transaction %Transaction{sender: "A", receiver: "B", num_inputs: 0, inputs: [], num_outputs: 0, outputs: [], trans_fee: 0, signature: ""}
  @block %Block{header: %Block.Header{prev_hash: "", merkle_root: "", timestamp: "", diff_target: "01", nonce: 0.3}, num_trans: 0, trans: []}

  def testHashTransaction() do
    IO.puts "Test hashTransaction()"
    IO.puts Alg.hashTransaction(@transaction)
  end

  def testHashBlock() do
    IO.puts "Test hashBlock()"
    IO.puts Alg.hashBlock(@block)
  end

  def testSignAndVerify() do
    IO.puts "Test sign message and verify it"
    {public_key, private_key} = Alg.generateKeyPair()
    signature = Alg.generateSignature(private_key, "message")
    IO.puts inspect Alg.verifySignature(signature, public_key, "message")
  end

  def testSignAndVerifyTransaction() do
    IO.puts "Test sign transaction and verify it"
    {sender_public_key, sender_private_key} = Alg.generateKeyPair()
    {receiver_public_key, receiver_private_key} = Alg.generateKeyPair()
    prev_trans_hash = "A"
    signature = Alg.signTransaction(sender_private_key, prev_trans_hash, receiver_public_key)
    IO.puts inspect Alg.verifyTransaction(signature, sender_public_key, prev_trans_hash, receiver_public_key)
  end

  def testGenerateFirstTransaction() do
    IO.puts "Test generateFirstTransaction()"
    pid = BlockChain.start()
    first_trans = Alg.generateFirstTransaction("A", 25, [], pid)
    IO.puts Alg.printObject(first_trans)
  end

  def testGenerateTransaction() do
    IO.puts "Test generateTransaction()"
    {sender_public_key, sender_private_key} = Alg.generateKeyPair()
    {receiver_public_key, receiver_private_key} = Alg.generateKeyPair()
    prev_trans_hash = "A"
    signature = Alg.signTransaction(sender_private_key, prev_trans_hash, receiver_public_key)
    pid = BlockChain.start()
    block = Alg.generateBlock(pid, [], "001", 0.9, "A", 25, "prev_hash")
    Alg.appendBlock(pid, block)
    Alg.printObject(Alg.generateTransaction("A", "B", signature, 10, 2, pid))
  end

  def testGenerateBlock() do
    IO.puts "Test generateBlock()"
    pid = BlockChain.start()
    block = Alg.generateBlock(pid, [], "001", 0.9, "A", 25, "prev_hash")
    Alg.printObject(block)
  end

  def testAppendBlock() do
    IO.puts "Test appendBlock()"
    pid = BlockChain.start()
    Alg.appendBlock(pid, @block)
    IO.puts "Blockchain after appending"
    Alg.printBlockChain(pid)
  end

  def testGetBalance() do
    IO.puts "Test getBalance()"
    pid = BlockChain.start()
    block = Alg.generateBlock(pid, [], "001", 0.9, "A", 25, "prev_hash")
    Alg.appendBlock(pid, block)
    IO.puts inspect Alg.getBalance("A", pid)
  end
end
