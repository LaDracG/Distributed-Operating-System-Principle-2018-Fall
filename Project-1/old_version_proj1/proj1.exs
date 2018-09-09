#require Boss
#require Worker

[n, k, num_workers] = System.argv()

# The arguments passed into through command line are string. 
# So we need to convert them to integers.
{n, _} = Integer.parse(n)
{k, _} = Integer.parse(k)
{num_workers, _} = Integer.parse(num_workers)

worker_list = []
ans = []
start = 1

#:observer.start()

Boss.start(n, k, worker_list, ans, start)

#for i <- Enum.to_list(1..num_workers) do
#	Worker.start()
#end

#IO.puts inspect Boss.pid()
#:timer.sleep(1000)
#Worker.start(Boss.pid())
#:timer.sleep(1000)
#IO.puts inspect Boss.pid()
#processes = []
#IO.puts inspect processes
"""
processes = 
	for i <- Enum.to_list(1..num_workers) do
		#IO.puts inspect processes
		pid = Worker.start(Boss.pid)
		#IO.puts i
		#IO.puts inspect pid
		#:timer.sleep(500+i)
		processes ++ [pid]
		#List.insert_at(processes, 0, pid)
	end
"""
startWorkers = fn func, li_pid, n_workers -> 
			if n_workers == 0 do
				li_pid
			else
				pid = Worker.start(Boss.pid)
				func.(func, li_pid ++ [pid], n_workers-1)
			end
		end

processes = startWorkers.(startWorkers, [], num_workers)

processes = processes ++ [Boss.pid]

#IO.puts inspect processes

Daemon.checkProcessAlive(processes)

#IO.puts inspect Boss.pid
