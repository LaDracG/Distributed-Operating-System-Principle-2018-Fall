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
      IO.puts inspect t.num_inputs
      t = %{t | num_inputs: 1}
      IO.puts inspect t.num_inputs
      loop()
    end
  end

  def loop() do
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
