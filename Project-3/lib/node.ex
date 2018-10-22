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

	def find_succesor() do
		GenServer.call(self(), {:find_suc, id})
	end

	def closest_preceding_node(fpid, id) do
		GenServer.call{:find_pre, id}, fpid)
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
		if (id > state[:key_n] and )