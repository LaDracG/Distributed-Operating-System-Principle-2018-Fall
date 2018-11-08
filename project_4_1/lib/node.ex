defmodule BitNode do
	use GenServer

	def init(state) do
		interval = Map.get(state, :flush_interval)
		state = Map.replace!(state, :timer, Process.send_after(self(), :time_up, interval))
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

	def start(flush_interval) do
		{:ok, pid} = GenServer.start_link(
						__MODULE__,
						%{
							:flush_interval => flush_interval,
							:txs => [], #cached transactions
							:queue => [], #uncached transactions in priority queue
							:timer => nil,
										#:current_tail => nil, #current tail of block list i.e. latest block
							:public_key => nil, #hex string
							:private_key => nil, #hex string
							:nodes => %{}, #pid => public key
							:r_nodes => %{}, #public key => pid
							:block_server => Block.start(),
										#:block_map => %{}, #map of block chain, hash_value => block
							:prev_transaction => %Transaction{}, #Transaction struct
							:initialized => false
						})
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

	def handle_call({:getBalance, owner}, from, state) do
		{:reply, Alg.getBalance(Map.get(state, :block_server), Map.get(Map.get(state, :nodes), owner)), state}
	end

	def handle_cast({:broadcast, msg}, state) do
		broadcast(msg)
		{:noreply, state}
	end

	def handle_cast({:rookie, nodes, r_nodes, block_table, tail, prev_transaction}, state) do
		if !Map.get(state, :initialized) do
			state = Map.replace!(state, :nodes, nodes)
			state = Map.replace!(state, :r_nodes, r_nodes)
						#state = Map.replace!(state, :current_tail, current_tail)
			state = Map.replace!(state, :prev_transaction, prev_transaction)
						#state = Map.replace!(state, :block_map, block_map)
			block_server = Map.get(state, :block_server)
			GenServer.cast(block_server, {:initialize, block_table, tail})
			state = Map.replace!(state, :initialized, true)
			GenServer.cast(self(), :process)
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
			prev_hash = Alg.hashTransaction(Map.get(state, :prev_transaction))
			sign = Alg.signTransaction(private_key, prev_hash, target_public_key)
			nodes = Map.get(state, :nodes)
			new_tx = Alg.generateTransaction(public_key, target_public_key, amount, fee, Map.get(state, :block_server))
						#new_tx = %Transaction{sender: Map.get(:nodes, self()), receiver: Map.get(:nodes, target), signature: sign} # TODO?
			broadcast({:new_tx, new_tx})
						#result = GenServer.call(target, {:receive_transaction, self(), new_tx})
		end
		{:noreply, state}
	end

	def handle_call(:public_key, from, state) do
		{:reply, Map.get(state, :public_key), state}
	end

	#create new block, empty txs
	def handle_info(:time_up, state) do
		if Map.get(state, :initialized) do
			interval = Map.get(state, :flush_interval)
			state = Map.replace!(state, :timer, Process.send_after(self(), :time_up, interval))
		
			txs = Map.get(state, :txs)
			diff_target = 0
			nonce = 0
			new_block = Alg.generateBlock(Map.get(state, :block_server), txs, diff_target, nonce)
			state = Map.replace!(state, :txs, [])
			#TODO mining functions
			#miner = BitNode.Miner.start()
			#GenServer.cast(miner, {:mine, block, self()})
		end
		{:noreply, state}
	end

	'''
	def handle_cast({:new_block, block_hash, block}, state) do
		block_map = Map.get(state, :block_map)
		if !Map.has_key?(block_map, block_hash) do
			block_map = Map.put(block_map, block_hash, block)
			state = Map.replace!(state, :block_map, block_map)
			state = Map.replace!(state, :current_tail, block_hash)
		end
		{:noreply, state}
	end
	'''
	def handle_cast({:new_block, block}, state) do
		if Map.get(state, :initialized) do
			res = Alg.appendBlock(Map.get(state, :block_server), block)
		end
		{:noreply, state}
	end

	def handle_cast({:new_node, pid, public_key}, state) do
		if Map.get(state, :initialized) do
			new_nodes = Map.put(Map.get(state, :nodes), pid, public_key)
			new_r_nodes = Map.put(Map.get(state, :r_nodes), public_key, pid)
			state = Map.replace!(state, :nodes, new_nodes)
			state = Map.replace!(state, :r_nodes, new_r_nodes)
						#current_tail = Map.get(state, :current_tail)
			prev_transaction = Map.get(state, :prev_transaction)
						#block_map = Map.get(state, :block_map)
			block_server = Map.get(state, :block_server)
			{block_table, tail} = GenServer.call(block_server, :getBlockTable)
			GenServer.cast(pid, {:rookie, new_nodes, new_r_nodes, block_table, tail, prev_transaction})
		end
		{:noreply, state}
	end

	# record new transaction
	def handle_cast({:new_tx, new_tx}, state) do
		if Map.get(state, :initialized) do
			queue = Map.get(state, :queue)
			queue = insert(queue, new_tx)
			state = Map.replace!(state, :queue, queue)
		end
		{:noreply, state}
	end

	#TODO faster
	def insert(queue, tx) do
		queue = queue ++ [tx]
		Enum.sort_by(queue, &(&1.trans_fee >= &2.trans_fee))
	end

	def handle_cast({:tx_failed, tx}, state) do
		#TODO
		{:noreply, state}
	end

	def handle_cast(:process, state) do
		queue = Map.get(state, :queue)
		if !Enum.empty?(queue) do
			new_tx = List.first(queue)
			queue = List.delete_at(queue, 0)
			state = Map.replace!(state, :queue, queue)
			sign = new_tx.signature
			sender_public_key = new_tx.sender
			receiver_public_key = new_tx.receiver
			prev_hash = Alg.hashTransaction(Map.get(state, :prev_transaction))
			sender = Map.get(Map.get(state, :r_nodes), sender_public_key)
			if Alg.verifyTransaction(sign, sender_public_key, prev_hash, receiver_public_key) do
				new_txs = Map.get(state, :txs) ++ [new_tx]
				state = Map.replace!(state, :txs, new_txs)
				state = Map.replace!(state, :prev_transaction, new_tx)
							#GenServer.cast(sender, {:tx_succeeded, tx})
			else
				GenServer.cast(sender, {:tx_failed, new_tx})
			end
		end
		GenServer.cast(self(), :process)
		{:noreply, state}
	end

	def handle_info(_, state) do
		{:ok, state}
	end
end