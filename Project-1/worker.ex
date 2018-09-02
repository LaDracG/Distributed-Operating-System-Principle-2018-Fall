defmodule Worker do
    
    def fetchTask do 
        send(Boss.pid, {self(), :fetch_task})
        receive do
            {:ok, task} -> returnResult(findBatchStartingNums(task))
            :no_task # no more tasks, do nothing 
        end
    end

    def returnResult(result) do 
        send(Boss.pid, {self(), :return_result, result})
    end

    def findBatchStartingNums(task) do
        res = []
        res = 
            for {k, n} <- task do
                res ++ findSingleStartingNum(k, n)
            end
        #res
        #IO.puts res
        returnResult(res)
    end

    def findSingleStartingNum(k, n) do
        res = []
        res =  
            for starting_num <- Enum.to_list(1..n) do
            #findSingleStartingNum(k, n-1) + getSquareSum(Enum.to_list(n..n+k-1))
            #IO.puts k, n, getSquareSum(Enum.to_list(starting_num..starting_num+k-1)) 
                if isSquare?(getSquareSum(Enum.to_list(starting_num..starting_num+k-1))) do
                    res ++ [starting_num]
                end 
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
    
    
end
