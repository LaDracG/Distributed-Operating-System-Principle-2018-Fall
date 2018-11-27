defmodule BitNode.Queue do
	use GenServer

	def init(state) do
		GenServer.cast(self(), :process)
		{:ok, state}
	end

	def start(master) do
		{:ok, pid} = GenServer.start_link(__MODULE__, 
										%{
											:queue => [],
											:txs => [],
											:prev_transaction => %Transaction{},
											:master => master
										})
		pid
	end

	def handle_cast({:insert, tx}, state) do
		queue = Map.get(state, :queue)
		queue = insert(queue, tx)
		state = Map.replace!(state, :queue, queue)
		{:noreply, state}
	end

	def handle_call(:get_queue, from, state) do
		{:reply, Map.get(state, :queue), state}
	end

	def handle_call(:get_txs, from, state) do
		{:reply, Map.get(state, :txs), state}
	end

	def handle_call(:get_prev_transaction, from, state) do
		{:reply, Map.get(state, :prev_transaction), state}
	end

	def handle_call(:deliver_txs, from, state) do
		txs = Map.get(state, :txs)
		state = Map.replace!(state, :txs, [])
		{:reply, txs, state}
	end

	def handle_cast({:set_queue, queue}, state) do
		state = Map.replace!(state, :queue, queue)
		{:noreply, state}
	end

	def handle_cast({:set_txs, txs}, state) do
		state = Map.replace!(state, :txs, txs)
		{:noreply, state}
	end

	def handle_cast({:set_prev_transaction, tx}, state) do
		state = Map.replace!(state, :prev_transaction, tx)
		{:noreply, state}
	end

	def insert(queue, tx) do
		if Enum.empty?(queue) do
			[tx]
		else
			[max | rest] = queue
			if tx.trans_fee > max.trans_fee do
				[tx | queue]
			else
				[max | insert(rest, tx)]
			end
		end
	end

	def handle_cast(:process, state) do
		queue = Map.get(state, :queue)
		state = 
			if !Enum.empty?(queue) do
				new_tx = List.first(queue)
				queue = List.delete_at(queue, 0)
				state = Map.replace!(state, :queue, queue)
				sign = new_tx.signature
				sender_public_key = new_tx.sender
				receiver_public_key = new_tx.receiver
				master = Map.get(state, :master)
				prev_transaction = Map.get(state, :prev_transaction)
				prev_hash = Alg.hashTransaction(prev_transaction)
				state = 
					if Alg.verifyTransaction(sign, sender_public_key, prev_hash, receiver_public_key) do
						new_txs = Map.get(state, :txs) ++ [new_tx]
						state = Map.replace!(state, :txs, new_txs)
						state = Map.replace!(state, :prev_transaction, new_tx)
					else
						IO.puts "x"
						state
					end
				state
			else
				state
			end
		GenServer.cast(self(), :process)
		{:noreply, state}
	end

end