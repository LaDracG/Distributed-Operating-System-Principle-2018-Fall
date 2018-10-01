"""
defmodule Algorithm do
  @alg_dict %{
    "gossip" => Algorithm.Gossip,
    "push-sum" => Algorithm.PushSum
  }

  def sendMsg(alg, neighbor_pid, state) do
    @alg_dict[alg].sendMsg()
  end


end

defmodule Algorithm.Gossip do
  use Genserver
  def sendMsg(alg, neighbor_pid, state) do
    msg = "_"
    GenServer.cast(neighbor_pid, {:receive_msg, msg})
  end
end

defmodule Algorithm.PushSum do
  use Genserver
  def sendMsg(alg, neighbor_pid, state) do
    msg = %{:s => 0.5 * state[:s], :w => 0.5 * state[:w]}

    GenServer.cast(neighbor_pid, {:receive_msg, msg})
  end
end

"""
