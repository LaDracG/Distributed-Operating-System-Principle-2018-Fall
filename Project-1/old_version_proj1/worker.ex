defmodule Worker do
    # TODO: Multi processes without duplicate names
    #def init(name) do
    @name :worker
    #end
    #@result_list []

    def fetchTask(boss_pid, is_new_process) do 
        if is_new_process do
            send(boss_pid, {self(), :fetch_task, []})    
        end
        receive do
            {:ok, start_n, end_n, k} ->
                #@result_list = [] 
                #IO.puts "worker: " <> inspect(start_n) <> inspect(end_n) <> inspect(k)
                #IO.puts "Result: " <> inspect(findSingleStartingNum(start_n, end_n, k))
                res = findSingleStartingNum(start_n, end_n, k)
                if res != [] do
                    send(boss_pid, {self(), :fetch_task, res})
                else
                    send(boss_pid, {self(), :fetch_task, [nil]})
                end
                fetchTask(boss_pid, false)
            {:no_task} -> stop() #IO.puts("Done") # no more tasks, do nothing 
        end
    end

    """
    def returnResult(result) do 
        send(Boss.pid, {self(), :return_result, result})
    end

    
    def findBatchStartingNums(start_n, end_n, k) do
        res = []
        res = 
            for {k, n} <- task do
                res ++ findSingleStartingNum(k, n)
            end
        #res
        #IO.puts res
        returnResult(res)
    end
    """

    def findSingleStartingNum(start_n, end_n, k) when start_n == end_n do
        #res = []
        res = 
            if isSquare?(getSquareSum(Enum.to_list(start_n..start_n+k-1))) do
                [start_n]                
            else
                []
            end
        res 
    end

    def findSingleStartingNum(start_n, end_n, k) do
        #res = []
        #res =  
        #for starting_num <- Enum.to_list(start_n..end_n) do
            #IO.puts inspect starting_num
            #findSingleStartingNum(k, n-1) + getSquareSum(Enum.to_list(n..n+k-1))
            #IO.puts k, n, getSquareSum(Enum.to_list(starting_num..starting_num+k-1)) 
            #if isSquare?(getSquareSum(Enum.to_list(starting_num..starting_num+k-1))) do
            #    res ++ [starting_num]                
            #end

        #end

        #IO.puts inspect res
        #res
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

    def pid, do: Process.whereis(@name) 

    def start(boss_pid) do
        #init(name)
		pid = spawn(__MODULE__, :fetchTask, [boss_pid, true])
        pid
        # Process.register(pid, @name) is to connect pid with a name such that we can use the name 
        # as identifier in function send/2 instead of only pid.
        # This registering is not necessary. So here we cancel it to avoid name conflict.
        #Process.register(pid, @name)
        
        # Send an empty list to identify this is a new worker process
        # send(boss_pid, {self(), :fetch_task, []})
	end

	def stop do
		Process.exit(pid(), :normal)
		Process.unregister(@name)
	end   

end
