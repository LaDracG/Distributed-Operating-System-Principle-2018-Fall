"""
defprotocol Topology do
    @doc "The interface for choosing corresponding topology structures according to args"
    def getNeighbor(topology_type)
end

defimpl Topology, for: Topology. do

end
"""


defmodule Topology do
    @topology_dict %{"full" => Topology.FullNetwork,
            "3D" => Topology.ThreeDimGrid,
            "rand2D" => Topology.Random2DGrid,
            "sphere" => Topology.Sphere,
            "line" => Topology.Line,
            "imp2D" => Topology.ImperfectLine
    }
    def getNeighbor(neighbors) do
        #case topology_type do
            """
            "full" -> Topology.FullNetwork.getNeighbor()
            "3D" -> Topology.FullNetwork.getNeighbor()
            "rand2D" -> Topology.FullNetwork.getNeighbor()
            "sphere" -> Topology.FullNetwork.getNeighbor()
            "line" -> Topology.FullNetwork.getNeighbor()
            "imp2D" -> Topology.FullNetwork.getNeighbor()
            """
        #end
        #@topology_dict[topology_type].getNeighbor()
        #if neighbors == [] do
        #    nil
        #else
        Enum.random(neighbors)
        #end
    end

    # return: a list of lists of neighbor node indices (0-based).
    #         the first list is neighbor node indices of the first node,
    #         the second list is neighbor node indices of the second node ...
    def computeAllNeighbors(num_nodes, topology_type) do
        #IO.puts inspect(@topology_dict[topology_type])
        @topology_dict[topology_type].computeAllNeighbors(num_nodes)
    end
end

defmodule Topology.FullNetwork do
    #def getNeighbor() do
    #    IO.puts "FullNetwork"
    #end

    def computeAllNeighbors(num_nodes) do
        Enum.map(Enum.to_list(0..num_nodes-1), fn node_idx -> Enum.to_list(0..num_nodes-1) -- [node_idx] end)
    end
end

defmodule Topology.ThreeDimGrid do
    #def getNeighbor() do
    #    IO.puts "ThreeDimGrid"
    #end


    def mod(x,y) do
        cond do
            x > 0 -> rem(x, y)
            x < 0 -> y + rem(x, y)
            x == 0 -> 0
        end
    end

    def computeAllNeighbors(num_nodes) do
        Enum.map(Enum.to_list(0..num_nodes-1), fn node_idx ->
                                                    Enum.filter(
                                                        [
                                                            trunc(node_idx / 4) * 4 + mod(node_idx - 1, 4),
                                                            trunc(node_idx / 4) * 4 + mod(node_idx + 1, 4),
                                                            node_idx + 4,
                                                            node_idx - 4
                                                        ],
                                                        fn neighbor_idx -> neighbor_idx < num_nodes and neighbor_idx >= 0 end
                                                    )
                                                end

        )
    end
end

defmodule Topology.Random2DGrid do
    #def getNeighbor() do
    #    IO.puts "Random2DGrid"
    #end
    def distance(p1, p2) do
        :math.sqrt(:math.pow(p1[:x] - p2[:x], 2) + :math.pow(p1[:y] - p2[:y], 2))
    end

    def computeAllNeighbors(num_nodes) do
        #IO.puts "1"
        points = Enum.map(Enum.to_list(0..num_nodes-1), fn node_idx -> %{:x=>:rand.uniform(), :y=>:rand.uniform(), :node_idx=>node_idx} end)
        #IO.puts "2"
        points = Enum.map(
            points,
            fn p ->
                Enum.map(Enum.filter(points -- [p], fn p2 -> distance(p, p2) < 0.1 end), fn p2 -> p2[:node_idx] end)
            end
        )
        #IO.puts "3"
        #IO.puts inspect(points)
        points
        #nodes = Enum.map(points, fn p -> p[:node_idx] end)
    end
end

defmodule Topology.Sphere do
    #def getNeighbor() do
    #    IO.puts "Sphere"
    #end

    def computeAllNeighbors(num_nodes) do

    end
end

defmodule Topology.Line do
    #def getNeighbor() do
    #    IO.puts "Line"
    #end

    def computeAllNeighbors(num_nodes) do
        Enum.map(Enum.to_list(0..num_nodes-1), fn node_idx ->
                                                    if node_idx - 1 < 0 do
                                                        [node_idx + 1]
                                                    else
                                                        if node_idx + 1 > num_nodes - 1 do
                                                            [node_idx - 1]
                                                        else
                                                            [node_idx - 1, node_idx + 1]
                                                        end
                                                    end
                                                end
                )
    end
end

defmodule Topology.ImperfectLine do
    #def getNeighbor() do
    #    IO.puts "ImperfectLine"
    #end

    def computeAllNeighbors(num_nodes) do
        Enum.map(
            Enum.to_list(0..num_nodes-1),
            fn node_idx ->
                Enum.filter(
                    [
                        node_idx - 1,
                        node_idx + 1,
                        Enum.random(Enum.to_list(0..num_nodes-1) -- [node_idx, node_idx - 1, node_idx + 1])
                    ],
                    fn neighbor_idx -> neighbor_idx >= 0 and neighbor_idx < num_nodes end
                )
            end
        )
    end
end
