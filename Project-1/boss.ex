defmodule Boss do
	@name :boss
	@work_unit 5
	
	def scheduler(s, n, k, ans) do
		receive do
			{worker_pid, :fetch_task, list} ->
				ans = ans ++ list
				e = s
				if s <= n do
					if s + @work_unit > n do
						e = n
					else
						e = s + @work_unit
					send(worker_pid, {:ok, s, e, k})
					end
					s = e + 1
				end
			{_, :print_ans} ->
				IO.puts ans
		end
		scheduler(s, n, k, ans)
	end

	def pid, do: Process.whereis(@name)

	def printAns do
		send(self(), :print_ans)
	end

	def start(n, k) do
		pid = spawn(__MODULE__, :scheduler, [0, n, k, []])
		Process.register(pid, @name)
	end

	def stop do
		Process.exit(pid(), :normal)
		Process.unregister(@name)
	end

end