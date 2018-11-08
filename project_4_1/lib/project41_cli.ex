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
      #Manager.start(num_nodes)
      t = %Transaction{}
      #IO.puts inspect t.num_inputs
      t = %{t | num_inputs: 1}
      #IO.puts inspect t.num_inputs
      #tlist = Map.values(Map.from_struct(t))
      #IO.puts inspect(tlist)
      #IO.puts inspect :crypto.hash(:sha256, tlist) #|> Base.encode16
      #IO.puts Alg.bin2hex(:crypto.hash(:sha256, tlist))
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
      loop()
    end
  end

  def loop() do
    loop()
  end

  def testChain() do
    chain = BlockChain.start()
    block = Alg.generateBlock(chain, [], 100, 10)
    Alg.appendBlock(chain, block)
    # TODO
  end
  """
  def waitNetworkFinish(net_pid) do
    if Process.alive?(net_pid) do
      waitNetworkFinish(net_pid)
    end
  end
  """
end
