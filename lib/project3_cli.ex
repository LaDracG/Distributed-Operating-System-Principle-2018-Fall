defmodule Project3.CLI do
  def main(args \\ []) do
    {opts, words, _} =
      OptionParser.parse(args, switches: [])
    #IO.puts inspect(word)
    [num_nodes, num_reqs] = words
    {num_nodes, _} = Integer.parse(num_nodes)
    {num_reqs, _} = Integer.parse(num_reqs)
    IO.puts inspect(num_nodes) <> " " <> inspect(num_reqs)
    if num_nodes < 3 do
      IO.puts "The number of peers cannot be less than 3!"
    else
      pids = Manager.start(self(), num_nodes)
      countConnections(0, 0, num_nodes)
    end
  end

  def countConnections(count, num_finish, num_peers) do
    receive do
      {:oneConnection} ->
        IO.puts "New connection, now the number of connecitons: " <> inspect(count + 1)
        countConnections(count + 1, num_finish, num_peers)
      {:finish, id, pid} ->
        new_num_finish = num_finish + 1
        if new_num_finish < num_peers do
          IO.puts "Peer (id: " <> inspect(id) <> " PID: " <> inspect(pid) <> ") finish"
          countConnections(count, new_num_finish, num_peers)
        else
          IO.puts "END, final connection number: " <> inspect(count)
        end
    end
  end
  """
  def checkProcessAlive(processes) do
    if processes == [] do # just end, do nothing
        "END"
    else
        if Process.alive?(hd(processes)) do
            checkProcessAlive(processes)
        else
            checkProcessAlive(tl(processes))
        end
    end
  end
  """
  """
  def waitNetworkFinish(net_pid) do
    if Process.alive?(net_pid) do
      waitNetworkFinish(net_pid)
    end
  end
  """
end
