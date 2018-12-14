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

  def start(f \\ false) do
    {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :tail => nil,
                            :block_table => %{},
                            :first? => f
                        }
                    )
    pid
  end

  def handle_call(:getTailBlock, from, state) do
    {:reply, Map.get(state, :tail), state}
  end

  def handle_call({:getBlock, block_hash}, from, state) do
    block =
      if block_hash != nil do
        Map.get(Map.get(state, :block_table), block_hash)
      else
        nil
      end
    {:reply, block, state}
  end

  def handle_call({:appendBlock, block}, from, state) do
    #state = Map.replace!(state, :tail, block)
    block_table = Map.get(state, :block_table)
    block_table = Map.put(block_table, Alg.hashBlock(block), block)
    state = Map.replace!(state, :block_table, block_table)
    state = Map.replace!(state, :tail, block)
    #IO.puts inspect state
    {:reply, :ok, state}
  end

  def handle_call(:getBlockTable, from, state) do
    block_table = Map.get(state, :block_table)
    tail = Map.get(state, :tail)
    {:reply, {block_table, tail}, state}
  end

  def handle_cast({:initialize, block_table, tail}, state) do
    state = Map.replace!(state, :block_table, block_table)
    state = Map.replace!(state, :tail, tail)
    {:noreply, state}
  end
end
