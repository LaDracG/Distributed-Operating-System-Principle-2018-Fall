defmodule Peer do
  use GenServer

  def init(state) do
    {:ok, state}
  end

  """
  def start(predecessor, finger_table) do
    {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :predecessor => predecessor,
                            :successor => nil,
                            :finger_table => finger_table
                        }
                    )
      pid
  end
  """

  def start(counter_pid, id, type) do
    {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :id => id,
                            :counter_pid => counter_pid,
                            :type => type,
                            :predecessor => nil,
                            :successor => nil,
                            :finger_table => nil,
                            #:predecessor => predecessor,
                            #:successor => sucessor,
                            #:finger_table => finger_table
                        }
                    )
    pid
  end

  #def genFingerTable(len_table, cur_peers, )
  """
  def genFingerTable(cur_peers, cur_num_peers) do
    # Insert new peer into circle
    for i <- Enum.to_list(0..cur_num_peers-2) do
      tup1 = Enum.at(cur_peers, i)
      tup2 = Enum.at(cur_peers, i+1)
      if Enum.at(tup, 0) <
    end
  end
  """

  def handle_call({:assignAttrs, pred, succ, fintb}, from, state) do
    state = Map.replace!(state, :predecessor, pred)
    state = Map.replace!(state, :successor, succ)
    state = Map.replace!(state, :finger_table, fintb)
    {:reply, :ok, state}
  end

  def handle_call(:getSucc, from, state) do
    {:reply, Map.get(state, :successor), state}
  end

  def handle_call(:getPred, from, state) do
    {:reply, Map.get(state, :predecessor), state}
  end

  def handle_call(:getType, from, state) do
    {:reply, Map.get(state, :type), state}
  end

  def handle_call(:getFintb, from, state) do
    {:reply, Map.get(state, :finger_table), state}
  end

  def handle_call(:getId, from, state) do
    {:reply, Map.get(state, :id), state}
  end
  """
  def handle_call(:getPid, from, state) do
    {:reply, self(), state}
  end
  """
  def handle_call(:getCounterPid, from, state) do
    {:reply, Map.get(state, :counter_pid), state}
  end

  def handle_cast({:requestAll, num_reqs}, state) do
    #IO.puts "Start all requests in node"
    #requestAll(num_reqs)
    #IO.puts "requestAll()"
    if num_reqs > 0 do
      :timer.sleep(1000)
      #IO.puts "1"
      finger_table = Map.get(state, :finger_table)
      m = length(finger_table)
      num_total = trunc(:math.pow(2, m))
      target_id = :rand.uniform(num_total) - 1
      #IO.puts "2"
      GenServer.cast(self(), {:requestOnce, target_id})
      #IO.puts "3"
      GenServer.cast(self(), {:requestAll, num_reqs - 1})
    else
      counter_pid = Map.get(state, :counter_pid)
      self_id = Map.get(state, :id)
      send(counter_pid, {:finish, self_id, self()})
    end
    {:noreply, state}
  end

  def handle_cast({:requestOnce, target_id}, state) do
    #requestOnce(target_id)
    self_state = state
    self_id = Map.get(self_state, :id)
    self_succ = Map.get(self_state, :successor)
    finger_table = Map.get(self_state, :finger_table)
    counter_pid = Map.get(self_state, :counter_pid)
    #{status, next_id_pid} =
    res = Algorithm.routingRequests(target_id, self_id, self_succ, finger_table)
    if res != nil do
      status = Enum.at(res, 0)
      next_id_pid = Enum.at(res, 1)
      #IO.puts "id: " <> inspect(self_id) <> " -- Request once"
      if status == :not_found do
        GenServer.cast(Enum.at(next_id_pid, 1), {:requestOnce, target_id})
      end
      send(counter_pid, {:oneConnection})
    end
    {:noreply, state}
  end
  """
  def handle_cast(:getState, state) do
    send(self(), {:state, state})
    {:noreply, state}
  end

  def getState() do
    GenServer.cast(self(), :getState)
    receive do
      {:state, state} ->
        state
    end
  end
  """
  """
  def requestOnce(target_id) do
    self_state = getState()
    self_id = Map.get(self_state, :id)
    self_succ = Map.get(self_state, :successor)
    finger_table = Map.get(self_state, :finger_table)
    counter_pid = Map.get(self_state, :counter_pid)
    {status, next_id_pid} = Algorithm.routingRequests(target_id, self_id, self_succ, finger_table)
    IO.puts "id: " <> inspect(self_id) <> " -- Request once"
    if status == :not_found do
      GenServer.cast(Enum.at(next_id_pid, 1), {:requestOnce, target_id})
    end
    send(counter_pid, {:oneConnection})
  end

  def requestAll(num_reqs) do
    IO.puts "requestAll()"
    if num_reqs > 0 do
      #:timer.sleep(1000)
      IO.puts "1"
      finger_table = Map.get(getState(), :finger_table)
      m = length(finger_table)
      num_total = trunc(:math.pow(2, m))
      target_id = :rand.uniform(num_total) - 1
      IO.puts "2"
      requestOnce(target_id)
      IO.puts "3"
      requestAll(num_reqs - 1)
    else
      counter_pid = Map.get(getState(), :counter_pid)
      self_id = Map.get(getState(), :id)
      send(counter_pid, {:finish, self_id, self()})
    end
  end
  """
end
