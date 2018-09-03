defmodule Worker do
    @name :worker
    @result_list []

    def fetchTask do 
        send(Boss.pid, {self(), :fetch_task, []})
        receive do
            {:ok, start_n, end_n, k} ->
                @result_list = [] 
                send(Boss.pid, {self(), :fetch_task, findSingleStartingNum(start_n, end_n, k)})
                fetchTask()
            :no_task -> IO.puts("Done") # no more tasks, do nothing 
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

    def start do
		pid = spawn(__MODULE__, :fetchTask, [])
		Process.register(pid, @name)
	end

	def stop do
		Process.exit(pid(), :normal)
		Process.unregister(@name)
	end   

end
