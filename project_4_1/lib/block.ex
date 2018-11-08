defmodule Block do
  defstruct header: nil, num_trans: 0, trans: []
end

defmodule Block.Header do
  defstruct prev_hash: "", merkle_root: "", timestamp: "", diff_target: nil, nonce: nil
end

defmodule BlockChain do
  use GenServer

  def init(state) do
    {:ok, state}
  end

  def start() do
    {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :tail => nil,
                            :block_table => %{}
                        }
                    )
    pid
  end

  def handle_call(:getTailBlock, from, state) do
    {:reply, Map.get(state, :tail), state}
  end

  def handle_call({:getBlock, block_hash}, from, state) do
    {:reply, Map.get(Map.get(state, :block_table), block_hash), state}
  end

  def handle_call({:appendBlock, block}, from, state) do
    state = Map.replace!(state, :tail, block)
    block_table = Map.get(state, :block_table)
    block_table = Map.put(block_table, Alg.hashBlock(block), block)
    state = Map.replace!(state, :block_table, block_table)
    state = Map.replace!(state, :tail, block)
    #IO.puts inspect state
    {:reply, :ok, state}
  end
end
