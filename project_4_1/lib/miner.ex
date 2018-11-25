defmodule BitNode.Miner do
	use GenServer
	@reward 25

	def init(state) do
		{:ok, state}
	end

	def start() do
		{:ok, pid} = GenServer.start_link(__MODULE__, 
										%{
											:enable_work => true,
											:working => false
											#:stop_prev_block_hash => ""
										})
		pid
	end

	def handle_cast(:stop, state) do
		state = 
			if Map.get(state, :working) do
				IO.puts "stopped"
				Map.replace!(state, :enable_work, false)
			else
				state
			end
		{:noreply, state}
	end

	def handle_cast(:initialize, state) do
		state = Map.replace!(state, :enable_work, true)
		state = Map.replace!(state, :working, false)
		{:noreply, state}
	end

	def handle_cast({:mine, block_server, txs, diff_target, miner_hash, prev_block_hash, pid}, state) do
		state = 
			if Map.get(state, :enable_work) do
				nonce = :rand.uniform()
				block = Alg.generateBlock(block_server, txs, diff_target, nonce, miner_hash, @reward)
				block_hash = Alg.hashBlock(block)
				state = 
					if !(block_hash < diff_target) do
						state = Map.replace!(state, :working, true)
						GenServer.cast(self(), {:mine, block_server, txs, diff_target, miner_hash, prev_block_hash, pid})
						state
					else
						#IO.puts "mining succeed"
						GenServer.cast(pid, {:new_block, block, prev_block_hash})
						GenServer.cast(pid, {:broadcast, {:new_block, block, prev_block_hash}})
						state = Map.replace!(state, :working, false)
						state = Map.replace!(state, :enable_work, true)
						state
					end
				state
			else
				state = Map.replace!(state, :enable_work, true)
				state = Map.replace!(state, :working, false)
				state
			end
		{:noreply, state}
	end
end