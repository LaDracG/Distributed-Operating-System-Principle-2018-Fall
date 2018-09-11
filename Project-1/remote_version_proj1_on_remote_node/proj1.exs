
defmodule Server do
        @name :worker_104_129_184_63

        def start() do
                pid = spawn(__MODULE__, :main, [])
                :global.register_name(@name, pid)
	end
	
	def startConnectionMonitor() do
		monitor_pid = spawn(__MODULE__, :connectionMonitor, [[]])	
		#:global.register_name(@name, monitor_pid)
	end	

	def connectionMonitor(node_list) do
		cur_node_list = Node.list()
                if cur_node_list -- node_list != [] do
                        IO.puts "New connections from " <> inspect(cur_node_list -- node_list) <> "; Current connections: " <> inspect(cur_node_list)
			:global.sync()
			IO.puts inspect :global.registered_names()
                else
                        if node_list -- cur_node_list != [] do
                                IO.puts "Connections ended from " <> inspect(node_list -- cur_node_list)  <> "; Current connections: " <> inspect(cur_node_list)
				#if Enum.member?(node_list -- cur_node_list, :"boss@127.0.0.1") do
				#	# if boss disconnected from this node, we should kill worker processes.
				#	
				#end
                        	:global.sync()
			end
                end
		connectionMonitor(cur_node_list)
	end
	
        def pid, do: :global.whereis_name(@name)
	
	def startWorkers(boss_pid, li_pid, n_workers) do
                if n_workers == 0 do
                        li_pid
                else
                        pid = Worker.start(boss_pid)
                        startWorkers(boss_pid, li_pid ++ [pid], n_workers-1)
                end
        end
	
        def main() do
                #cur_node_list = Node.list()
                #if cur_node_list -- node_list != [] do
                #        IO.puts "New connections from " <> inspect(cur_node_list -- node_list) <> "; Current connections: " <> inspect(cur_node_list)
                #else
                #        if node_list -- cur_node_list != [] do
                #                IO.puts "Connections ended from " <> inspect(node_list -- cur_node_list)  <> "; Current connections: " <> inspect(cur_node_list)
                #        end
                #end
                receive do
			{:wakeUp, remote_src, num_workers} -> 
				IO.puts "Get msg from " <> inspect(remote_src) <> ": num_workers -- " <> inspect(num_workers)
				processes = startWorkers(remote_src, [], num_workers)
				#processes = processes ++ [Boss.pid]
				IO.puts "Worker Processes: " <> inspect(processes)
				Daemon.checkProcessAlive(processes)
			
                        {:test, remote_src, msg} ->
                                IO.puts "Received a msg from " <> inspect(remote_src) <> ": \"" <> msg <> "\""
                                send(remote_src, {:ok, Node.self(), "Got it."})
                end

                main()
        end

        def loop() do
                loop()
        end

end


Node.start(:"worker@104.129.184.63")
Node.set_cookie(:elixir)
#Node.connect(:"worker@104.129.184.63")
#Node.connect(:"worker@23.106.134.177")

Server.start()
Server.startConnectionMonitor()
Server.loop()

#IO.puts inspect Node.list

#[n, k] = System.argv()

# The arguments passed into through command line are string. 
# So we need to convert them to integers.
#{n, _} = Integer.parse(n)
#{k, _} = Integer.parse(k)

#worker_list = []
#ans = []
#start = 1

#num_workers = trunc(:math.sqrt(:math.sqrt(:math.sqrt(n * k)))) + 3
#num_workers = 2

#IO.puts "process number: " <> inspect num_workers
#:observer.start()

#Boss.start(n, k, worker_list, ans, start)

#startWorkers = fn func, li_pid, n_workers -> 
#			if n_workers == 0 do
#				li_pid
#			else
#				pid = Worker.start(Boss.pid)
#				func.(func, li_pid ++ [pid], n_workers-1)
#			end
#		end

#processes = startWorkers.(startWorkers, [], num_workers)
#processes = processes ++ [Boss.pid]

#Daemon.checkProcessAlive(processes)
