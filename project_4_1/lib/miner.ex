defmodule BitNode.Miner do
	use GenServer

	def init(state) do
		{:ok, state}
	end

	def start() do
		{:ok, pid} = GenServer.start_link(__MODULE__, %{})
	end

	def handle_cast({:mine, block, pid}, state) do
		block_hash = Alg.hashBlock(block)
		if !Alg.validHash(block_hash) do
			GenServer.cast(self(), {:mine, block, pid})
		else
			GenServer.cast(pid, {:new_block, block})
			GenServer.cast(pid, {:broadcast, {:new_block, block}})
		end
		{:noreply, state}
	end
end