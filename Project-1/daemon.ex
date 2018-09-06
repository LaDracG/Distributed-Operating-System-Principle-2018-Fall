defmodule Daemon do
    def checkProcessAlive(processes) do
        if processes == [] do # just end, do nothing
            "END"
        else
            #IO.puts inspect processes
            #IO.puts inspect hd(processes)
            if Process.alive?(hd(hd(processes))) do 
                checkProcessAlive(processes)
            else
                checkProcessAlive(tl(processes))
            end
        end			
    end
end

