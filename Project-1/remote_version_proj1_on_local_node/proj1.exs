
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

Node.start(:"boss@127.0.0.1")
Node.set_cookie(:elixir)
Node.connect(:"worker@104.129.184.63")
Node.connect(:"worker@23.106.134.177")

boss_pid = Boss.start(n, k, worker_list, ans, start)

#IO.puts inspect Node.list
#IO.puts inspect :global.registered_names()
#IO.puts inspect :global.whereis_name(:worker_104_129_184_63)
:global.sync()
#IO.puts inspect :global.registered_names()
#IO.puts inspect :global.whereis_name(:worker_104_129_184_63)

pid_remote_node_1 = :global.whereis_name(:worker_104_129_184_63)
pid_remote_node_2 = :global.whereis_name(:worker_23_106_134_177)

send(pid_remote_node_1, {:wakeUp, boss_pid, num_workers})
send(pid_remote_node_2, {:wakeUp, boss_pid, num_workers})

#processes = startWorkers.(startWorkers, [], num_workers)
#processes = processes ++ [Boss.pid]

Daemon.checkProcessAlive([boss_pid])
