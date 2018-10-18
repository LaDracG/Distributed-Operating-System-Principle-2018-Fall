defmodule Project3.CLI do
  def main(args \\ []) do
    {opts, words, _} =
      OptionParser.parse(args, switches: [])
    #IO.puts inspect(word)
    [num_nodes, num_reqs] = words
    {num_nodes, _} = Integer.parse(num_nodes)
    {num_reqs, _} = Integer.parse(num_reqs)
    IO.puts inspect(num_nodes) <> " " <> inspect(num_reqs)
  end


  """
  def waitNetworkFinish(net_pid) do
    if Process.alive?(net_pid) do
      waitNetworkFinish(net_pid)
    end
  end
  """
end
