defmodule BitNode.Miner do
	use GenServer

	def init(state) do
		{:ok, state}
	end

	def start() do
		{:ok, pid} = GenServer.start_link(__MODULE__, %{})
	end

	def handle_cast({:mine, block_server, txs, diff_target, pid}, state) do
		nonce = :rand.uniform()
		block = Alg.generateBlock(block_server, txs, diff_target, nonce)
		block_hash = Alg.hashBlock(block)
		if !(block_hash < diff_target) do
			GenServer.cast(self(), {:mine, block_server, txs, diff_target, pid})
		else
			GenServer.cast(pid, {:new_block, block})
			GenServer.cast(pid, {:broadcast, {:new_block, block}})
		end
		{:noreply, state}
	end
end