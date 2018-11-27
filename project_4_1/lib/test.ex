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

  def testBitCoin() do
    node_list = Test.Node.testStartNode(3)
    Test.Node.loop(node_list)
  end
end

defmodule Test.Node do
    # start a single node and return its pid
    def testStartNode() do
      {:ok, _} = Registry.start_link(keys: :duplicate, name: Registry.PubSubTest, partitions: System.schedulers_online) # essential
      pid = BitNode.start(true)
      blockchain_pid = GenServer.call(pid, :blockchain_pid)
      public_key = GenServer.call(pid, :public_key)
      b = Alg.generateBlock(blockchain_pid, [], 0, 0, public_key, 25, "")
      Alg.appendBlock(blockchain_pid, b)
      GenServer.cast(pid, :start_mining)
      pid
    end

    # start nodes of number nodenum, return the nodes' pids as a list
    def testStartNode(nodenum) do
      {:ok, _} = Registry.start_link(keys: :duplicate, name: Registry.PubSubTest, partitions: System.schedulers_online) # essential
      first_pid = BitNode.start(true)
      blockchain_pid = GenServer.call(first_pid, :blockchain_pid)
      public_key = GenServer.call(first_pid, :public_key)
      b = Alg.generateBlock(blockchain_pid, [], 0, 0, public_key, 25, "")
      Alg.appendBlock(blockchain_pid, b)
      
      node_list = []
      node_list = 
        if nodenum >= 2 do
            for _ <- 2..nodenum do
              BitNode.start()
            end
        end
      node_list = [first_pid] ++ node_list
      IO.puts inspect node_list
      GenServer.cast(first_pid, :start_mining)
      node_list
    end

    # start a transaction with random sender, receiver, transaction amount and transaction fee
    def testRandomTransaction(node_list) do
      sender = Enum.at(node_list, Enum.random(0..length(node_list) - 1))
      receiver = Enum.at(node_list, Enum.random(0..length(node_list) - 1))
      amount = :rand.uniform() * 10 |> Float.round(2)
      trans_fee = amount * :rand.uniform() |> Float.round(2)
      GenServer.cast(sender, {:ask_transaction, receiver, amount, trans_fee})
    end

    # print the balance of a node
    def testCheckBalance(pid) do
      public_key = GenServer.call(pid, :public_key)
      blockchain_pid = GenServer.call(pid, :blockchain_pid)
      IO.puts inspect(pid) <> "balance: "
      IO.puts inspect Alg.getBalance(public_key, blockchain_pid)
    end

    # print the blockchain stored in a node
    def testCheckBlockchain(pid) do
      blockchain_pid = GenServer.call(pid, :blockchain_pid)
      IO.puts inspect(pid) <> "blockchain: "
      Alg.printBlockChain(blockchain_pid)
    end

    # start a random transaction every 1.5s, and check each node's current balance
    # transaction may fail, when transaction amount is larger than sender's balance
    def loop(node_list) do
      :timer.sleep(1500)
      Test.Node.testRandomTransaction(node_list)
      for nodeIndex <- 0..length(node_list) - 1 do
        Test.Node.testCheckBalance(Enum.at(node_list, nodeIndex))
      end
      IO.puts "\n"
      loop(node_list)
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
