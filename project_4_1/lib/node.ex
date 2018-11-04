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
		state = Map.replace!(state, :nodes, new_nodes)
		broadcast({:new_node, self(), public_key})
		#GenServer.cast(self(), {:broadcast, {:new_node, self(), public_key}})
		#GenServer.cast({:via, :BitNode, 'bitcoin'}, {:new_node, self(), public_key})
		{:ok, state}
	end

	def start(flush_interval) do
		{:ok, pid} = GenServer.start_link(
						__MODULE__,
						%{
							:flush_interval => flush_interval,
							:txs => [], #cached transactions
							:timer => nil,
							:current_tail => nil, #current tail of block list
							:public_key => nil, #hex string
							:private_key => nil, #hex string
							:nodes => %{}, #pid => public key
							:prev_transaction => nil, #Transaction struct
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

	def handle_cast({:rookie, nodes, current_tail, prev_transaction}, state) do
		if !Map.get(state, :initialized) do
			GenServer.cast(self(), {:initialize, nodes, current_tail, prev_transaction})
		end
		{:noreply, state}
	end

	def handle_cast({:initialize, nodes, current_tail, prev_transaction}, state) do
		state = Map.replace!(state, :nodes, nodes)
		state = Map.replace!(state, :current_tail, current_tail)
		state = Map.replace!(state, :prev_transaction, prev_transaction)
		state = Map.replace!(state, :initialized, true)
		{:noreply, state}
	end

	# ask for a transaction
	def transaction(target) do
		GenServer.cast(self(), {:ask_transaction, target})
	end

	def handle_cast({:ask_transaction, target}, state) do
		target_public_key = Map.get(Map.get(state, :nodes), target)
		private_key = Map.get(state, :private_key)
		prev_hash = Alg.hashTransaction(Map.get(state, :prev_transaction))
		sign = Alg.signTransaction(private_key, prev_hash, target_public_key)
		new_tx = %Transaction{signature: sign}
		result = GenServer.call(target, {:receive_transaction, self(), new_tx})
		{:noreply, state}
	end

	def handle_call({:receive_transaction, sender, new_tx}, state) do
		sign = new_tx.signature
		sender_public_key = Map.get(Map.get(state, :nodes), sender)
		private_key = Map.get(state, :private_key)
		prev_hash = Alg.hashTransaction(Map.get(state, :prev_transaction))
		if Alg.verifyTransaction(sign, sender_public_key, prev_hash, private_key) do
			GenServer.cast(self(), {:new_tx, new_tx})
			broadcast({:new_tx, new_tx})
			{:reply, true}
		else
			{:reply, false}
		end
	end

	def handle_info(:time_up, state) do
		interval = Map.get(state, :flush_interval)
		state = Map.replace!(state, :timer, Process.send_after(self(), :time_up, interval))
		GenServer.cast(self(), :new_block)
		state = Map.replace!(state, :txs, [])
		{:noreply, state}
	end

	def handle_info(_, state) do
		{:ok, state}
	end

	def handle_cast({:new_node, pid, public_key}, state) do
		new_nodes = Map.put(Map.get(state, :nodes), pid, public_key)
		state = Map.replace!(state, :nodes, new_nodes)
		current_tail = Map.get(state, :current_tail)
		prev_transaction = Map.get(state, :prev_transaction)
		GenServer.cast(pid, {:rookie, new_nodes, current_tail, prev_transaction})
		{:noreply, state}
	end

	# record new transaction
	def handle_cast({:new_tx, new_tx}, state) do
		new_txs = Map.get(state, :txs) ++ [new_tx]
		state = Map.replace!(state, :txs, new_txs)
		state = Map.replace!(state, :prev_transaction, new_tx)
		{:noreply, state}
	end

	# flush interval time up, create and broadcast
	def handle_cast(:new_block, state) do
		txs = Map.get(state, :txs)
		#root = Alg.generateMerkelTree(txs)
		current_tail = Map.get(state, :current_tail)
		new_block = nil#%Block{} to be filled
		state = Map.replace!(state, :current_tail, new_block)
		IO.puts 'new block created'
		#IO.inspect(Map.get(state, :nodes))
		{:noreply, state}
	end
end