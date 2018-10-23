defmodule Manager do
  def main(counter_pid, num_peers, num_reqs) do
    len_tb = trunc(:math.ceil(:math.log2(num_peers)))
    num_total = trunc(:math.pow(2, len_tb))
    #IO.puts "total: " <> inspect(num_total) <> " peers: " <> inspect(num_peers)
    types = Enum.shuffle(List.duplicate(1, num_peers) ++ List.duplicate(0, num_total - num_peers))
    pids = startAllPeers(counter_pid, 0, types, [])
    #IO.puts "Start all nodes"
    #IO.puts inspect(pids)
    #IO.puts "Assign attributes"
    assignAttrs(0, pids, len_tb)
    #IO.puts inspect(pids)
    #for i <- Enum.to_list(1..num_total) do
    #  id = Enum.at(Enum.at(pids, i-1), 0)
    #  pid = Enum.at(Enum.at(pids, i-1), 1)
    #  IO.puts "id: " <> inspect(id) <> " type: " <> inspect(getType(id, pids)) <> " Pred: " <> inspect(closestPred(id, pids)) <> " Succ: " <> inspect(findSucc(id, pids)) <> " FinTB: " <> inspect(getFintb(id, pids))
    #end
    #IO.puts "Start requesting"
    startAllRequests(pids, num_reqs)
  end

  def start(counter_pid, num_peers, num_reqs) do
    spawn(__MODULE__, :main, [counter_pid, num_peers, num_reqs])
  end

  def startAllPeers(counter_pid, cur_id, types, pids) do
    if types != [] do
      pids = pids ++ [[cur_id, Peer.start(counter_pid, cur_id, hd(types))]]
      startAllPeers(counter_pid, cur_id + 1, tl(types), pids)
    else
      pids
    end
  end

  def assignAttrs(i, pids, len_tb) do
    if i < length(pids) do
      id = Enum.at(Enum.at(pids, i), 0)
      #IO.puts inspect(id)
      pred = closestPred(id, pids)
      succ = findSucc(id, pids)
      fintb = genFintb(id, pids, 0, len_tb, [])
      GenServer.call(Enum.at(Enum.at(pids, i), 1), {:assignAttrs, pred, succ, fintb})
      assignAttrs(i+1, pids, len_tb)
    end
  end

  def startAllRequests(pids, num_reqs) do
    if pids != [] do
      pid = Enum.at(hd(pids), 1)
      type = GenServer.call(pid, :getType)
      if type == 1 do
        GenServer.cast(pid, {:requestAll, num_reqs})
      end
      startAllRequests(tl(pids), num_reqs)
    end
  end

  def findSucc(id, pids) do
    findNextNonFile(id, pids)
  end

  def closestPred(id, pids) do
    findPrevNonFile(mod(id - 1, length(pids)), pids)
  end

  def genFintb(id, pids, i, len_tb, fintb) do
    if i < len_tb do
      id_pid = findNextNonFile(mod(id + trunc(:math.pow(2, i)), length(pids)), pids)
      fintb = fintb ++ [id_pid]
      genFintb(id, pids, i+1, len_tb, fintb)
    else
      fintb
    end
  end

  def locate(id, pids, i) do
    if Enum.at(Enum.at(pids, i), 0) == id do
      i
    else
      locate(id, pids, i + 1)
    end
  end

  def mod(x,y) do
    cond do
        x > 0 -> rem(x, y)
        x < 0 -> y + rem(x, y)
        x == 0 -> 0
    end
  end

  def getType(id, pids) do
    cur_loc = locate(id, pids, 0)
    cur_pid = Enum.at(Enum.at(pids, cur_loc), 1)
    cur_type = GenServer.call(cur_pid, :getType)
    #IO.puts "Current type: " <> inspect(cur_type)
    cur_type
  end

  def getFintb(id, pids) do
    cur_loc = locate(id, pids, 0)
    cur_pid = Enum.at(Enum.at(pids, cur_loc), 1)
    cur_fintb = GenServer.call(cur_pid, :getFintb)
  end

  def findNextNonFile(id, pids) do
    cur_type = getType(id, pids)
    if cur_type == 0 do
      findNextNonFile(mod(id + 1, length(pids)), pids)
    else
      Enum.at(pids, locate(id, pids, 0))
    end
  end

  def findPrevNonFile(id, pids) do
    cur_type = getType(id, pids)
    if cur_type == 0 do
      findNextNonFile(mod(id - 1, length(pids)), pids)
    else
      Enum.at(pids, locate(id, pids, 0))
    end
  end
end
