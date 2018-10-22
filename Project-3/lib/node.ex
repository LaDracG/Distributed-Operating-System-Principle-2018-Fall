defmodule node do
	use GenServer

	def start_link(opts) do
		GenServer.start_link(__MODULE__, :ok, opts)
	end

	def create() do
		GenServer.cast(self(), {:create})
	end

	#npid: any existing node's pid
	def join(npid) do
		GenServer.cast(self(), {:join, npid})
	end

	def find_succesor(id) do
		GenServer.call(self(), {:find_suc, id})
	end

	def closest_preceding_node(id) do
		GenServer.call(self(), {:find_pre, id})
	end

	def fix_fingers(fpid) do
		GenServer.cast({:fix_fingers, finger_table}, pid)
	end

	def notify() do
	end

	def init() do
		{:ok, 
		 [pid: self(),
		  key_n: 0
		  successor: nil,
		  predecessor: nil,
		  finger_table: Map.new()
		 ]
		}
	end

	def handle_cast({:create}, _from, state) do
		state[:succesor] = self()
		fix_fingers(self())
	end

	def handle_cast({:join, npid}, _from, state) do
		send(npid, {:find_succesor, self()})
		# (state[:succesor] = receive {npid, :succesor_found, succesor})
		# (stabilize())
		# (nofify(npid))
		# (fix_fingers())
	end

	def handle_call({:find_suc, id}, _from, state) do
		if (id > state[:key_n] and id < state[:succesor]) do
			{:reply, state[:succesor], state}
		else do
			np = closest_preceding_node(id)
			# (np.find_succesor(id))
		end
	end