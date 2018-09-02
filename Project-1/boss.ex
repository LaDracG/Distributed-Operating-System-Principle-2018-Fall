defmodule Boss do
	@name :boss
	@work_unit 5
	@worker_list []
	@ans []
	@start 1
	
	def scheduler(n, k) do
		receive do
			{worker_pid, :fetch_task, list} ->
				@worker_list = @worker_list -- [worker_pid]
				@ans = @ans ++ list
				e = 
					if @start <= n do
						if @start + @work_unit > n do
							n
						else
							@start + @work_unit - 1
						end
					end
				if @start <= n do
					send(worker_pid, {:ok, @start, e, k})
				else
					send(worker_pid, {:no_task})
				end
				@worker_list = 
					if @start <= n do
						@worker_list ++ [worker_pid]
					end
				@start = 
					if @start <= n do
						@start + @work_unit
					end

			{_, :print_ans} ->
				for num <- @ans do
					IO.puts num
				end
		end
		if @start > n and @worker_list == [] do
			for num <- @ans do
				IO.puts num
			end
		else
			scheduler(n, k)
		end
	end

	def pid, do: Process.whereis(@name)

	def printAns do
		send(self(), :print_ans)
	end

	def start(n, k) do
		pid = spawn(__MODULE__, :scheduler, [n, k])
		Process.register(pid, @name)
	end

	def stop do
		Process.exit(pid(), :normal)
		Process.unregister(@name)
	end

end