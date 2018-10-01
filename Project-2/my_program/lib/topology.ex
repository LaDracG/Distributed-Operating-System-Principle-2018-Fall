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
        Enum.random(neighbors)
    end

    # return: a list of lists of neighbor node indices (0-based).
    #         the first list is neighbor node indices of the first node,
    #         the second list is neighbor node indices of the second node ...
    def computeAllNeighbors(num_nodes, topology_type) do

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

    def computeAllNeighbors(num_nodes) do

    end
end

defmodule Topology.Random2DGrid do
    #def getNeighbor() do
    #    IO.puts "Random2DGrid"
    #end

    def computeAllNeighbors(num_nodes) do

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

    end
end

defmodule Topology.ImperfectLine do
    #def getNeighbor() do
    #    IO.puts "ImperfectLine"
    #end

    def computeAllNeighbors(num_nodes) do

    end
end
