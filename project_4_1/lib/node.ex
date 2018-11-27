defmodule BitNode do
	use GenServer
	@diff_target "0001"

	def init(state) do
		reg('bitcoin')
		{public_key, private_key} = Alg.generateKeyPair()
		state = Map.replace!(state, :public_key, public_key)
		state = Map.replace!(state, :private_key, private_key)
		new_nodes = Map.put(Map.get(state, :nodes), self(), public_key)
		new_r_nodes = Map.put(Map.get(state, :r_nodes), public_key, self())
		state = Map.replace!(state, :nodes, new_nodes)
		state = Map.replace!(state, :r_nodes, new_r_nodes)
		broadcast({:new_node, self(), public_key})
		{:ok, state}
	end

	def start(first? \\ false) do
		{:ok, pid} = GenServer.start_link(
						__MODULE__,
						%{
							:queue => BitNode.Queue.start(self()),
							:public_key => nil, #hex string
							:private_key => nil, #hex string
							:nodes => %{}, #pid => public key
							:r_nodes => %{}, #public key => pid
							:block_server => BlockChain.start(),
							:initialized => if first? do
												true
											else
												false
											end,
							:current_miner => BitNode.Miner.start(),
							:first? => first?
						})
		pid
	end

	def reg(topic) do
		{:ok, _} = Registry.register(Registry.PubSubTest, topic, [])
	end

	def broadcast(msg) do
		Registry.dispatch(Registry.PubSubTest, 'bitcoin', 
						fn entries -> for {pid, _} <- entries, do: if pid != self(), do: GenServer.cast(pid, msg)
					end)
	end

	def getBalance(owner) do
		GenServer.call(self(), {:getBalance, owner})
	end

	def handle_call({:getPid, public_key}, from, state) do
		{:reply, Map.get(Map.get(state, :r_nodes), public_key), state}
	end

	def handle_call({:getBalance, owner}, from, state) do
		{:reply, Alg.getBalance(Map.get(state, :block_server), Map.get(Map.get(state, :nodes), owner)), state}
	end

	def handle_cast({:broadcast, msg}, state) do
		broadcast(msg)
		{:noreply, state}
	end

	#for test
	def handle_call(:blockchain_pid, from, state) do
		{:reply, Map.get(state, :block_server), state}
	end

	def handle_call(:prev_transaction, from, state) do
		{:reply, Map.get(state, :prev_transaction), state}
	end

	def handle_call(:public_key, from, state) do
		{:reply, Map.get(state, :public_key), state}
	end

	def handle_cast({:rookie, nodes, r_nodes, block_table, tail, prev_transaction, txs, queue}, state) do
		state = 
			if !Map.get(state, :initialized) do
				state = Map.replace!(state, :nodes, nodes)
				state = Map.replace!(state, :r_nodes, r_nodes)
				#state = Map.replace!(state, :prev_transaction, prev_transaction)
				GenServer.cast(Map.get(state, :block_server), {:initialize, block_table, tail})
				GenServer.cast(Map.get(state, :queue), {:set_txs, txs})
				GenServer.cast(Map.get(state, :queue), {:set_queue, queue})
				GenServer.cast(Map.get(state, :queue), {:set_prev_transaction, prev_transaction})
				state = Map.replace!(state, :initialized, true)
				state
			else
				state
			end
		{:noreply, state}
	end

	def handle_call({:getBlock, block_hash}, from, state) do
		{:reply, GenServer.call(Map.get(state, :block_server), {:getBlock, block_hash}), state}
	end

	# ask for a transaction
	def transaction(target, amount, fee) do
		GenServer.cast(self(), {:ask_transaction, target, amount, fee})
	end

	def handle_cast({:ask_transaction, target, amount, fee}, state) do
		if Map.get(state, :initialized) do
			target_public_key = Map.get(Map.get(state, :nodes), target)
			public_key = Map.get(state, :public_key)
			private_key = Map.get(state, :private_key)
			prev_transaction = GenServer.call(Map.get(state, :queue), :get_prev_transaction)
			prev_hash = Alg.hashTransaction(prev_transaction)
			sign = Alg.signTransaction(private_key, prev_hash, target_public_key)
			nodes = Map.get(state, :nodes)
			new_tx = Alg.generateTransaction(public_key, target_public_key, sign, amount, fee, Map.get(state, :block_server))
			if new_tx != nil do
				GenServer.cast(self(), {:new_tx, new_tx})
				broadcast({:new_tx, new_tx})
			end
		end
		{:noreply, state}
	end

	#create new block, empty txs
	def handle_cast(:start_mining, state) do
		#IO.inspect self()
		#IO.puts inspect(self()) <> "Start mining.."
		state = 
			if Map.get(state, :initialized) do
				txs = GenServer.call(Map.get(state, :queue), :deliver_txs)
				diff_target = @diff_target
				block_server = Map.get(state, :block_server)
				miner_hash = Map.get(state, :public_key)
				prev_block_hash = Alg.hashBlock(Alg.getTailBlock(block_server))
				miner = Map.get(state, :current_miner)
				GenServer.cast(miner, {:mine, block_server, txs, diff_target, miner_hash, prev_block_hash, self(), nil})
				state
			else
				state
			end
		{:noreply, state}
	end

	def handle_cast({:new_block, block, prev_block_hash}, state) do
		state = 
		if Map.get(state, :initialized) do
			#IO.puts inspect(Map.get(state, :queue)) <> inspect(self())
			prev_hash = Alg.hashBlock(Alg.getTailBlock(Map.get(state, :block_server)))
			#IO.inspect prev_hash
			state = 
				if Alg.hashBlock(block) < @diff_target and prev_hash == prev_block_hash do
					#IO.inspect self()
					stopRes = GenServer.call(Map.get(state, :current_miner), :stop)
					if !stopRes do
						GenServer.cast(Map.get(state, :current_miner), :initialize)
					end
					res = Alg.appendBlock(Map.get(state, :block_server), block)
					GenServer.cast(Map.get(state, :queue), {:set_prev_transaction, Enum.at(block.trans, 0)})
					#state = Map.replace!(state, :prev_transaction, Enum.at(block.trans, 0))
					GenServer.cast(self(), :start_mining)
					state
				end
			state
		end
		#IO.inspect Alg.hashBlock(Alg.getTailBlock(Map.get(state, :block_server)))
		{:noreply, state}
	end

	def handle_cast({:new_node, pid, public_key}, state) do
		state = 
			if Map.get(state, :initialized) do
				new_nodes = Map.put(Map.get(state, :nodes), pid, public_key)
				new_r_nodes = Map.put(Map.get(state, :r_nodes), public_key, pid)
				state = Map.replace!(state, :nodes, new_nodes)
				state = Map.replace!(state, :r_nodes, new_r_nodes)
				prev_transaction = GenServer.call(Map.get(state, :queue), :get_prev_transaction)
				block_server = Map.get(state, :block_server)
				txs = GenServer.call(Map.get(state, :queue), :get_txs)
				queue = GenServer.call(Map.get(state, :queue), :get_queue)
				{block_table, tail} = GenServer.call(block_server, :getBlockTable)
				GenServer.cast(pid, {:rookie, new_nodes, new_r_nodes, block_table, tail, prev_transaction, txs, queue})
				state
			else
				state
			end
		{:noreply, state}
	end

	# record new transaction
	def handle_cast({:new_tx, new_tx}, state) do
		if Map.get(state, :initialized) do
			GenServer.cast(Map.get(state, :queue), {:insert, new_tx})
		end
		{:noreply, state}
	end

	def handle_cast({:tx_failed, tx}, state) do
		#IO.puts "transaction_failed"
		#IO.inspect tx
		{:noreply, state}
	end

	def handle_info(_, state) do
		{:ok, state}
	end
end