defmodule Project2.CLI do
  @topology_dict %{"full" => Topology.FullNetwork,
            "3D" => Topology.ThreeDimGrid,
            "rand2D" => Topology.Random2DGrid,
            "sphere" => Topology.Sphere,
            "line" => Topology.Line,
            "imp2D" => Topology.ImperfectLine
    }
  @alg_dict %{
      "gossip" => 0,
      "push-sum" => 1
    }

  def main(args \\ []) do
    {opts, words, _} =
      OptionParser.parse(args, switches: [])
    #IO.puts inspect(word)
    [num_nodes, topology_type, alg] = words
    {num_nodes, _} = Integer.parse(num_nodes)
    if num_nodes <= 1 do
      IO.puts "[Error] The number of nodes must be larger than 1"
    else
      if @alg_dict[alg] == nil do
        IO.puts "[Error] Invalid algorithm: " <> alg
      else
        if @topology_dict[topology_type] == nil do
          IO.puts "[Error] Invalid topology: " <> topology_type
        else
          #Network.startNodes()
          net_pid = Network.start(num_nodes, topology_type, alg)
          waitNetworkFinish(net_pid)
          #IO.puts inspect(start_time) <> " " <> inspect(end_time)
        end
      end
    end
  end

  def waitNetworkFinish(net_pid) do
    if Process.alive?(net_pid) do
      waitNetworkFinish(net_pid)
    end
  end
end
