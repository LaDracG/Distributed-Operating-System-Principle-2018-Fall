defmodule Project41.CLI do
  def main(args \\ []) do
    {opts, words, _} =
      OptionParser.parse(args, switches: [])
    #IO.puts inspect(word)
    [num_nodes] = words
    {num_nodes, _} = Integer.parse(num_nodes)
    #{num_reqs, _} = Integer.parse(num_reqs)
    #IO.puts inspect(num_nodes) <> " " <> inspect(num_reqs)
    if num_nodes < 3 do
      IO.puts "The number of peers cannot be less than 3!"
    else
      #nodes_list = []
      #nodes_list = add_nodes(num_nodes, nodes_list)
      testChain()
      '''
      #Manager.start(num_nodes)
      t = %Transaction{}
      #IO.puts inspect t.num_inputs
      t = %{t | num_inputs: 1}
      #IO.puts inspect t.num_inputs
      #tlist = Map.values(Map.from_struct(t))
      #IO.puts inspect(tlist)
      #IO.puts inspect :crypto.hash(:sha256, tlist) #|> Base.encode16
      #IO.puts Alg.bin2hex(:crypto.hash(:sha256, tlist))
      """
      {public_key1, private_key1} = Alg.generateKeyPair()
      {public_key2, private_key2} = Alg.generateKeyPair()
      hash = Alg.hashString(:sha256, "1", 2)
      sig = Alg.signTransaction(private_key1, hash, public_key2)
      IO.puts sig
      IO.puts Alg.verifyTransaction(sig, public_key1, hash, public_key2)
      {:ok, _} = Registry.start_link(keys: :duplicate, name: Registry.PubSubTest, partitions: System.schedulers_online)
      {:ok, pid1} = BitNode.start(1000)
      :timer.sleep(3000)
      {:ok, pid2} = BitNode.start(1000)
      :timer.sleep(100)
      GenServer.cast(pid1, {:ask_transaction, pid2})
      #sig = Alg.generateSignature(private_key, "1")
      #IO.puts inspect Alg.verifySignature(public_key, sig, "2")
      #IO.puts inspect Alg.hashTransaction(t)
      """
      testChain()
      loop()
      '''
    end
  end
  '''
  def add_nodes(num_nodes, nodes_list) do
    if num_nodes == 0 do
      nodes_list
    else
      nodes_list = nodes_list ++ [BitNode.start()]
      add_nodes(num_nodes - 1, nodes_list)
    end
  end
  '''

  def loop() do
    loop()
  end

  def testChain() do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: Registry.PubSubTest, partitions: System.schedulers_online) # essential
    {:ok, pid1} = BitNode.start(1000, true)
    public_key_1 = GenServer.call(pid1, :public_key)
    blockchain_pid_1 = GenServer.call(pid1, :blockchain_pid)
    t = Alg.generateTransaction(public_key_1, public_key_1, 10000, 0, blockchain_pid_1, 0)
    GenServer.cast(pid1, {:init_prev_tx, t})
    #Alg.printObject(t)
    b = Alg.generateBlock(blockchain_pid_1, [t], 0, 0)
    Alg.appendBlock(blockchain_pid_1, b)
    #IO.puts Alg.getBalance(blockchain_pid_1, public_key_1)
    :timer.sleep(2000)
    {:ok, pid2} = BitNode.start(1000)
    #:timer.sleep(100)
    #GenServer.cast(pid1, {:ask_transaction, pid2, 0, 0})
    #Alg.printBlockChain(blockchain_pid_1)
    :timer.sleep(2000)
    GenServer.cast(pid1, {:ask_transaction, pid2, 0, 0})
    #IO.puts Alg.getBalance(blockchain_pid_1, public_key_1)
    loop()
  end
  """
  def waitNetworkFinish(net_pid) do
    if Process.alive?(net_pid) do
      waitNetworkFinish(net_pid)
    end
  end
  """
end
