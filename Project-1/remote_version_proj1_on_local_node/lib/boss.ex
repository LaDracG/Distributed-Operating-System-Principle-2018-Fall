defmodule Boss do
	# Do not try to use module attributes to record intermediate states
	# Module attributes are immutable.
	# So the better way is passing the states as parameters into the next function call. 
	@name :boss_localhost
	@work_unit 1000000
	
	def scheduler(n, k, worker_list, ans, start) do
		receive do
			{worker_pid, :fetch_task, list} ->
				worker_list = 
					if list != [] do
						worker_list -- [worker_pid]
					else
						# We must assign var to itself if no change happened.
						# If we do not care about this case, the var will be nil instead of keeping original value in this case.
						worker_list 
					end
				
				ans = 
					if list == [nil] do
						ans
					else
						ans ++ list
					end	
				
				e = 
					if start <= n do
						if start + @work_unit > n do
							n
						else
							start + @work_unit - 1
						end
					end

				if start <= n do
					send(worker_pid, {:ok, start, e, k})
				else
					send(worker_pid, {:no_task})
				end

				worker_list = 
					if start <= n do
						worker_list ++ [worker_pid]
					else
						worker_list
					end
					
				start = 
					if start <= n do
						start + @work_unit
					else
						start
					end
				#IO.puts inspect(worker_list)
				#IO.puts start
				#IO.puts n
				#IO.puts inspect(ans)
				#IO.puts "Test"

				if start > n and worker_list == [] do
					#IO.puts "Task Done. Results: "
					ans = Enum.sort(ans)
					for num <- ans do
						IO.puts num
					end
					stop()
				else
					#IO.puts "Continue"
					scheduler(n, k, worker_list, ans, start)
				end

			{_, :print_ans} ->
				for num <- ans do
					IO.puts num
				end
		end
		
	end

	#def pid, do: Process.whereis(@name)

	def printAns do
		send(self(), :print_ans)
	end

	def start(n, k, worker_list, ans, start) do
		pid = spawn(__MODULE__, :scheduler, [n, k, worker_list, ans, start])
		#Process.register(pid, @name)
		:global.register_name(@name, pid)
		pid
	end

	def stop do
		#Process.exit(pid(), :normal)
		#Process.unregister(@name)
		:global.unregister_name(@name)
	end

end
