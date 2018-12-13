defmodule Project41.CLI do
  def main(args \\ []) do
    '''
    post_body = "hello!"
    rep = HTTPoison.request(:post, "http://127.0.0.1:4000", post_body, [])
    #IO.inspect rep
    '''
    IO.puts "Start testing algorithms: \n\n"
    Test.testAlg()

    IO.puts "\n\n"
    IO.puts "Start testing bitcoin functions: \n\n"
    Test.testBitCoin()
    
    #testChain()
  end


  '''
  def loop(blockchain_pid_1, blockchain_pid_2, public_key_1, public_key_2, public_key_3, blockchain_pid_3) do
    :timer.sleep(1000)

    #IO.puts "New block chain: \n"
    #Alg.printObject(Alg.getTailBlock(blockchain_pid_1))
    #Alg.printBlockChain(blockchain_pid_2)
    IO.puts "node 1 balance:"
    IO.puts Alg.getBalance(public_key_1, blockchain_pid_1)
    IO.puts "node 2 balance:"
    IO.puts Alg.getBalance(public_key_2, blockchain_pid_2)
    IO.puts "node 3 balance: \n"
    IO.puts Alg.getBalance(public_key_3, blockchain_pid_3)
    IO.puts ""
    loop(blockchain_pid_1, blockchain_pid_2, public_key_1, public_key_2, public_key_3, blockchain_pid_3)
  end

  def testChain() do
    {:ok, _} = Registry.start_link(keys: :duplicate, name: Registry.PubSubTest, partitions: System.schedulers_online) # essential
    pid1 = BitNode.start(true)
    public_key_1 = GenServer.call(pid1, :public_key)
    blockchain_pid_1 = GenServer.call(pid1, :blockchain_pid)
    #t = Alg.generateTransaction(public_key_1, public_key_1, 10000, 0, blockchain_pid_1, 0)
    #t = Alg.generateTransaction(public_key_1, public_key_1, 10000, 0, blockchain_pid_1)
    #GenServer.cast(pid1, {:init_prev_tx, t}) # init first tx
    #Alg.printObject(t)
    b = Alg.generateBlock(blockchain_pid_1, [], 0, 0, public_key_1, 25, "")
    Alg.appendBlock(blockchain_pid_1, b)

    pid2 = BitNode.start()
    blockchain_pid_2 = GenServer.call(pid2, :blockchain_pid)
    public_key_2 = GenServer.call(pid2, :public_key)


    pid3 = BitNode.start()
    blockchain_pid_3 = GenServer.call(pid3, :blockchain_pid)
    public_key_3 = GenServer.call(pid3, :public_key)


    IO.puts "initial node 1 balance: \n"
    IO.puts Alg.getBalance(public_key_1, blockchain_pid_1)

    IO.puts "initial node 2 balance: \n"
    IO.puts Alg.getBalance(public_key_2, blockchain_pid_2)

    IO.puts "initial node 3 balance: \n"
    IO.puts Alg.getBalance(public_key_3, blockchain_pid_3)

    IO.puts "node 1:"
    IO.inspect inspect(pid1) <> public_key_1
    IO.puts "node 2:"
    IO.inspect inspect(pid2) <> public_key_2
    IO.puts "node 3:"
    IO.inspect inspect(pid3) <> public_key_3
    #IO.puts "Initial block chain: \n"
    #Alg.printBlockChain(blockchain_pid_1)

    :timer.sleep(1000)
    IO.puts "Transaction: node 1 to node 2, amount 10, trans_fee 2 \n"
    GenServer.cast(pid1, {:ask_transaction, pid2, 10, 2})

    GenServer.cast(pid1, :start_mining)
    
    #GenServer.cast(pid1, {:ask_transaction, pid2, 0, 0})

    #:timer.sleep(1000)
    #Alg.printBlockChain(blockchain_pid_1)
    #:timer.sleep(1000)
    #Alg.printBlockChain(blockchain_pid_1)
    #:timer.sleep(1000)
    #Alg.printBlockChain(blockchain_pid_1)
    #IO.puts Alg.getBalance(blockchain_pid_1, public_key_1)
    loop(blockchain_pid_1, blockchain_pid_2,  public_key_1, public_key_2, public_key_3, blockchain_pid_3)
  end
  '''

end
