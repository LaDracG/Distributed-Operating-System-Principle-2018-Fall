
Node.start(:"boss@localhost")
Node.set_cookie(:elixir)
Node.connect(:"worker@104.129.184.63")
Node.connect(:"worker@23.106.134.177")

IO.puts inspect Node.list

[n, k] = System.argv()

# The arguments passed into through command line are string. 
# So we need to convert them to integers.
{n, _} = Integer.parse(n)
{k, _} = Integer.parse(k)

worker_list = []
ans = []
start = 1

num_workers = trunc(:math.sqrt(:math.sqrt(:math.sqrt(n * k)))) + 3

#IO.puts "process number: " <> inspect num_workers
#:observer.start()

Boss.start(n, k, worker_list, ans, start)

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

Daemon.checkProcessAlive(processes)
