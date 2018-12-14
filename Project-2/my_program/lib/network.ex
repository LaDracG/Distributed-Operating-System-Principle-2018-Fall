defmodule Network do
  @doc "Master and daemon process for managing nodes.
        It will calculate neighbors of each node and then start all nodes with their neighbor lists as parameters.
        (Network process would not maintain neghbor lists, they are maintained by nodes themselves)
        When all above done, Network chooses a node to start propagation.
      "
 # use GenServer
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

  def startNodes(num_nodes, topology_type, alg, node_pids) do
    if num_nodes == 0 do
      node_pids
    else
      pid = NetWork.Node.start(self(), topology_type, alg, [num_nodes])
      startNodes(num_nodes - 1, topology_type, alg, node_pids ++ [pid])
    end
  end

  # assignAllNeighbors - Compute and assign neighbor lists to all nodes
  def assignAllNeighbors(node_pids, topology_type) do
    # here all_neighbor_lists is a list of lists
    #IO.puts "here"
    all_neighbor_lists = Topology.computeAllNeighbors(length(node_pids), topology_type)
    #IO.puts "there"
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
    #send(node_pid, {self(), :assign_neighbors, neighbors})
    GenServer.cast(node_pid, {:setNeighbors, neighbors})
  end

  #def handle_call(:markNodeInit, node_pid, map_pids) do
  #  map_pids = Map.replace!(map_pids, "uninit_node_pids", map_pids["uninit_node_pids"] -- [node_pid])
  #  {:no_reply, map_pids}
  #end

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


  def startPropgation(node_pids) do
    if node_pids == [] do
      {:no_alive_pid, nil}
    else
      start_node_pid = Enum.random(node_pids)
      status = GenServer.call(start_node_pid, :startPropgation)
      if status != :ok do # starting failed
        startPropgation(node_pids -- [start_node_pid])
      else
        {:ok, start_node_pid}
      end
    end
  end

  def waitNodesFinish(node_pids, last_node, same_count, max_same_node_count) do
    if max_same_node_count == same_count do
      # do nothing
    else
      if node_pids != [] do
        receive do
          {node_pid, :finish} ->
              {status, start_node_pid} = startPropgation(node_pids -- [node_pid])
              if status == :ok do
                #IO.puts "[Network] " <> inspect(node_pid) <> " finish; Restart Prop on " <> inspect(start_node_pid)
                cond do
                  last_node == nil ->
                    waitNodesFinish(node_pids -- [node_pid], node_pid, 0, max_same_node_count)
                  node_pid == last_node ->
                    waitNodesFinish(node_pids -- [node_pid], node_pid, same_count + 1, max_same_node_count)
                  node_pid != last_node and last_node != nil ->
                    waitNodesFinish(node_pids -- [node_pid], last_node, same_count, max_same_node_count)
                end
              end
        end
      end
    end
  end
  def main(num_nodes, topology_type, alg) do
    node_pids = startNodes(num_nodes, topology_type, alg, [])
    #IO.puts inspect(node_pids)
    assignAllNeighbors(node_pids, topology_type)
    waitNodesInitilized(node_pids)
    startPropgation(node_pids)

    start_time = Time.utc_now()
    waitNodesFinish(node_pids, nil, 0, 5)
    end_time = Time.utc_now()
    IO.puts inspect(Time.diff(end_time, start_time, :microsecond)/1000) <> "ms"
    #IO.puts "================ END of Network ===================="
  end

  def start(num_nodes, topology_type, alg) do
    #GenServer.start_link(__MODULE__, node_pids)
    spawn(__MODULE__, :main, [num_nodes, topology_type, alg])
  end

  #def init(node_pids) do
  #  {:ok, %{"node_pids"=>node_pids, "uninit_node_pids"=>node_pids}}
  #end

end


defmodule NetWork.Node do
  use GenServer
  """
  def setNeighbors() do
    receive do
      {boss_pid, :assign_neighbors, neighbors} ->
        send(boss_pid, {self(), :init})
        neighbors
    end
  end
  """
  def handle_cast({:setNeighbors, neighbors}, state) do
    state = Map.replace!(state, :neighbors, neighbors)
    #state = Map.replace!(state, :neighbors, neighbors)
    send(state[:boss_pid], {self(), :init})
    #IO.puts inspect(self()) <> " sets neighbors"
    {:noreply, state}
  end

  """
  def reportFinish(boss_pid) do
    send(boss_pid, {self(), :finish})
  end
  """
  #def handle_call(:getState, from, state) do
  #  {:reply, state, state}
  #end

  #def getState() do
  #  GenServer.call(self(), :getState)
  #end

  def handle_cast({:removeNeighbor, neighbor_pid}, state) do
    state = Map.replace!(state, :neighbors, state[:neighbors] -- [neighbor_pid])
    if state[:neighbors] == [] do
      state = Map.replace!(state, :finish, true)
      send(state[:boss_pid], {self(), :finish})
      #IO.puts inspect(self()) <> " neighbors: " <> inspect(state[:neighbors])
      #IO.puts inspect(self()) <> " Finished because no neighbors"
      {:noreply, state}
    else
      #IO.puts inspect(self()) <> " neighbors: " <> inspect(state[:neighbors])
      {:noreply, state}
    end
  end

  #def removeNeighbor(neighbor_pid) do
  #  GenServer.cast(self(), {:removeNeighbor, neighbor_pid})
  #end

  def handle_cast({:receiveMsg, msg}, state) do
      #IO.puts inspect(self()) <> "receiveMsg" #<> inspect(from)
      if state[:alg] == "gossip" do
        if state[:finish] == false do
          if state[:count] >= state[:max_count] do
            # Do nothing, no longer transmit msg
            #IO.puts inspect(self()) <> " Finished because done"
            for neighbor_pid <- state[:neighbors] do
              #IO.puts inspect(self()) <> " start cast for removeNeighbor to " <> inspect(neighbor_pid)
              GenServer.cast(neighbor_pid, {:removeNeighbor, self()})
              #IO.puts inspect(self()) <> " end cast for removeNeighbor to " <> inspect(neighbor_pid)
            end
            state = Map.replace!(state, :finish, true)
            state = Map.replace!(state, :neighbors, [])
            send(state[:boss_pid], {self(), :finish})
            {:noreply, state}
          else # normal
            state = Map.replace!(state, :count, state[:count] + 1)
            next_neib = Topology.getNeighbor(state[:neighbors])
            #if next_neib != nil do
            GenServer.cast(next_neib, {:receiveMsg, "_"})
            #else
            #end
            {:noreply, state}
          end
        else
          send(state[:boss_pid], {self(), :finish})
          #IO.puts inspect(self()) <> " gossip count: " <> inspect(state[:count])
          {:noreply, state}
        end
      else # push-sum
        if state[:finish] == false do
          if state[:unchange_rounds] >= 3 do
            # Do nothing, no longer transmit msg
            #IO.puts inspect(self()) <> " Finished because done"
            for neighbor_pid <- state[:neighbors] do
              #IO.puts inspect(self()) <> " start cast for removeNeighbor"
              GenServer.cast(neighbor_pid, {:removeNeighbor, self()})
              #IO.puts inspect(self()) <> " end cast for removeNeighbor"
            end
            state = Map.replace!(state, :finish, true)
            state = Map.replace!(state, :neighbors, [])
            send(state[:boss_pid], {self(), :finish})
            #state = Map.replace!(state, :finish, true)
            # terminate here
            {:noreply, state}
          else # normal
            state = Map.replace!(state, :s, state[:s] + msg[:s])#.replace!(state, :w, state[:w] + msg[:w])
            state = Map.replace!(state, :w, state[:w] + msg[:w])
            if abs(state[:ratio] - state[:s] / state[:w]) <= :math.pow(10, -3) do
              state = Map.replace!(state, :unchange_rounds, state[:unchange_rounds] + 1)#.replace!(state, :ratio, state[:s] / state[:w])
              state = Map.replace!(state, :ratio, state[:s] / state[:w])
              next_neib = Topology.getNeighbor(state[:neighbors])
              sendMsg(next_neib)
              {:noreply, state}
            else
              state = Map.replace!(state, :unchange_rounds, 0)#.replace!(state, :ratio, state[:s] / state[:w])
              state = Map.replace!(state, :ratio, state[:s] / state[:w])
              next_neib = Topology.getNeighbor(state[:neighbors])
              sendMsg(next_neib)
              {:noreply, state}
            end
          end
        else
          send(state[:boss_pid], {self(), :finish})
          {:noreply, state}
        end
      end
  end

  def handle_cast({:sendMsg, neighbor_pid}, state) do
    #state = getState()
    #IO.puts inspect(self()) <> "sendMsg to " <> inspect(neighbor_pid)
    alg = state[:alg]
    if state[:alg] == "gossip" do
      msg = "_"
      #IO.puts inspect(self()) <> " start cast for receiveMsg"
      GenServer.cast(neighbor_pid, {:receiveMsg, msg})
      #IO.puts inspect(self()) <> " end cast for receiveMsg"
      {:noreply, state}
    else # push-sum
      msg = %{:s => 0.5 * state[:s], :w => 0.5 * state[:w]}
      GenServer.cast(neighbor_pid, {:receiveMsg, msg})
      state = Map.replace!(state, :s, 0.5 * state[:s])
      state = Map.replace!(state, :w, 0.5 * state[:w])
      {:noreply, state}
    end
  end

  def sendMsg(neighbor_pid) do
    #IO.puts inspect(self()) <> " start cast for sendMsg"
    GenServer.cast(self(), {:sendMsg, neighbor_pid})
    #IO.puts inspect(self()) <> " end cast for sendMsg"
  end

  def handle_call(:startPropgation, from, state) do
    if state[:neighbors] == [] do
      {:reply, :no_neighbors, state}
    else
      neib = Topology.getNeighbor(state[:neighbors])
      sendMsg(neib)
      {:reply, :ok, state}
    end
  end
  """
  def listen(boss_pid, topology_type, neighbors) do
    # TODO
    IO.puts inspect(self()) <> " " <> inspect(neighbors) <> " " <> inspect(Topology.getNeighbor(neighbors))
    reportFinish(boss_pid)
  end
  """
  """
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
  """
  def start(boss_pid, topology_type, alg, args) do
    if alg == "gossip" do
      {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :topology_type=>topology_type,
                            :alg=>alg,
                            :boss_pid=>boss_pid,
                            :neighbors=>[],
                            :count=>0,
                            :max_count=>10,
                            :finish=>false
                        }
                    )
      pid
    else
      {:ok, pid} = GenServer.start_link(
                      __MODULE__,
                      %{
                        :topology_type=>topology_type,
                        :alg=>alg,
                        :boss_pid=>boss_pid,
                        :neighbors=>[],
                        :s=>Enum.at(args, 0),
                        :w=>1,
                        :unchange_rounds=>0,
                        :ratio=>Enum.at(args, 0),
                        :finish=>false
                     }
                   )
      pid
    end
  end

  def init(state) do
    {:ok, state}
  end
  """
  def start(boss_pid, topology_type) do
		spawn(__MODULE__, :main, [boss_pid, topology_type, []])
  end
  """
end
