defmodule Network do
  @doc "Master and daemon process for managing nodes.
        It will calculate neighbors of each node and then start all nodes with their neighbor lists as parameters.
        (Network process would not maintain neghbor lists, they are maintained by nodes themselves)
        When all above done, Network chooses a node to start propagation.
      "
  """
  @topology_dict %{"full" => Topology.FullNetwork,
      "3D" => Topology.ThreeDimGrid,
      "rand2D" => Topology.Random2DGrid,
      "sphere" => Topology.Sphere,
      "line" => Topology.Line,
      "imp2D" => Topology.ImperfectLine
  }
  """
  """
  def startNodes(boss_pid, num_nodes, topology_type) do
    all_neighbor_lists = Topology.computeAllNeighbors(num_nodes, topology_type)
    node_pids = startNodes(boss_pid, num_nodes, topology_type, 0, [], all_neighbor_lists)
    node_pids
  end

  def startNodes(boss_pid, num_nodes, topology_type, cur_node_idx, node_pids, all_neighbor_lists) do
    if cur_node_idx == num_nodes do
      node_pids
    else
      pid = NetWork.Node.start(boss_pid, all_neighbor_lists[cur_node_idx])
      startNodes(boss_pid, num_nodes, topology_type, cur_node_idx+1, node_pids ++ [pid], all_neighbor_lists)
    end
  end
  """

  def mapIndicesToPids(cur_node_idx, all_neighbor_lists, node_pids, map_output) do
    if cur_node_idx == length(node_pids) do
      map_output
    else
      cur_node_pid = Enum.at(node_pids, cur_node_idx)
      cur_neighbor_indices = Enum.at(all_neighbor_lists, cur_node_idx)
      #IO.puts inspect(node_pids)
      #IO.puts inspect(node_pids[1])
      cur_neighbor_pids = Enum.map(cur_neighbor_indices, fn node_idx -> Enum.at(node_pids, node_idx) end)
      #IO.puts inspect(cur_neighbor_pids)
      map_output = Map.put(map_output, cur_node_pid, cur_neighbor_pids)

      #node_pids = node_pids -- [cur_node_pid]
      #all_neighbor_lists = all_neighbor_lists -- [cur_neighbor_indices]

      mapIndicesToPids(cur_node_idx + 1, all_neighbor_lists, node_pids, map_output)
    end
  end

  def startNodes(num_nodes, topology_type, node_pids) do
    if num_nodes == 0 do
      node_pids
    else
      pid = NetWork.Node.start(self(), topology_type)
      startNodes(num_nodes - 1, topology_type, node_pids ++ [pid])
    end
  end

  # assignAllNeighbors - Compute and assign neighbor lists to all nodes
  def assignAllNeighbors(node_pids, topology_type) do
    # here all_neighbor_lists is a list of lists
    all_neighbor_lists = Topology.computeAllNeighbors(length(node_pids), topology_type)
    #IO.puts inspect(all_neighbor_lists)
    # here all_neighbor_lists is a map where each key is a node pid
    # and value is a list of pids of neighbors of the node
    all_neighbor_lists = mapIndicesToPids(0, all_neighbor_lists, node_pids, %{})
    for {node_pid, neighbor_list} <- all_neighbor_lists do
      assignNeighbors(node_pid, neighbor_list)
    end
  end

  # assignNeighbors - Assign neighbor list to specific node with node_pid
  def assignNeighbors(node_pid, neighbors) do
    send(node_pid, {self(), :assign_neighbors, neighbors})
  end

  def waitNodesInitilized(uninit_node_pids) do
    if uninit_node_pids == [] do
      true
    else
      receive do
        {node_pid, :init} ->
          waitNodesInitilized(uninit_node_pids -- [node_pid])
      end
    end
  end


  def startPropgation(start_node_pid) do
    # TODO
  end

  def main(num_nodes, topology_type) do
    node_pids = startNodes(num_nodes, topology_type, [])
    assignAllNeighbors(node_pids, topology_type)
    waitNodesInitilized(node_pids)
    # TODO
  end

  def start(num_nodes, topology_type) do
    spawn(__MODULE__, :main, [num_nodes, topology_type])
  end

end


defmodule NetWork.Node do
  def setNeighbors() do
    receive do
      {boss_pid, :assign_neighbors, neighbors} ->
        send(boss_pid, {self(), :init})
        neighbors
    end
  end

  def reportFinish(boss_pid) do
    send(boss_pid, {self(), :finish})
  end

  def listen(boss_pid, topology_type, neighbors) do
    # TODO
    IO.puts inspect(self()) <> " " <> inspect(neighbors) <> " " <> inspect(Topology.getNeighbor(neighbors))
    reportFinish(boss_pid)
  end

  def main(boss_pid, topology_type, neighbors) do
    #send(boss_pid, {self(), :started})
    if neighbors == [] do
      neighbors = setNeighbors()
      main(boss_pid, topology_type, neighbors)
    else
      listen(boss_pid, topology_type, neighbors)
      #main(boss_pid, topology_type, neighbors)
    end
  end

  def start(boss_pid, topology_type) do
		spawn(__MODULE__, :main, [boss_pid, topology_type, []])
  end
end
