defmodule Worker do
    @name :worker_104_129_184_63

    def fetchTask(boss_pid, is_new_process) do 
	if is_new_process do
            send(boss_pid, {self(), :fetch_task, []})    
        end
        receive do
            {:ok, start_n, end_n, k} ->
                res = findSingleStartingNum(start_n, end_n, k)
                if res != [] do
                    send(boss_pid, {self(), :fetch_task, res})
                else
                    send(boss_pid, {self(), :fetch_task, [nil]})
                end
                fetchTask(boss_pid, false)

            {:no_task} -> stop() #IO.puts("Done") # no more tasks, do nothing 
        after
	    5_000 -> IO.puts "No respond from boss within 5s, stop worker process."
	end
    end

    def findSingleStartingNum(start_n, end_n, k) when start_n == end_n do
        res = 
            if isSquare?(getSquareSum(Enum.to_list(start_n..start_n+k-1))) do
                [start_n]                
            else
                []
            end
        res 
    end

    def findSingleStartingNum(start_n, end_n, k) do
        res = 
            if isSquare?(getSquareSum(Enum.to_list(start_n..start_n+k-1))) do
                findSingleStartingNum(start_n+1, end_n, k) ++ [start_n]
            else
                findSingleStartingNum(start_n+1, end_n, k)
            end
        res
    end

    def getSquareSum(nums) when nums == [] do
        0
    end

    def getSquareSum([head_num|tail_nums]) do
        getSquareSum(tail_nums) + head_num * head_num
    end

    def isSquare?(num) do
        if :math.sqrt(num) == trunc(:math.sqrt(num)) do
            true
        else
            false
        end
    end

    #def pid, do: :global.whereis_name(@name) 

    def start(boss_pid) do
	pid = spawn(__MODULE__, :fetchTask, [boss_pid, true])
        #:global.register_name(@name, pid)
	pid
        # Process.register(pid, @name) is to connect pid with a name such that we can use the name 
        # as identifier in function send/2 instead of only pid.
        # This registering is not necessary. So here we cancel it to avoid name conflict.
        #Process.register(pid, @name)
        
        # Send an empty list to identify this is a new worker process
        # send(boss_pid, {self(), :fetch_task, []})
	end

	def stop do
		#Process.exit(pid(), :normal)
		#Process.unregister(@name)
	end   
	
	#def hibernate() do
	#	receive do
	#		{:wakeUp, boss_pid} -> 
				 
	#	end
	#end
end
