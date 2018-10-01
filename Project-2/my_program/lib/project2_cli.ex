defmodule Project2.CLI do
  def main(args \\ []) do
    {opts, words, _} =
      OptionParser.parse(args, switches: [])
    #IO.puts inspect(word)
    [num_nodes, topology_type, algorithm] = words
    {num_nodes, _} = Integer.parse(num_nodes)
    Network.start(num_nodes, topology_type)
    loop()
  end

  def loop() do
    loop()
  end
end
