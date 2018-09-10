defmodule Daemon do
    def checkProcessAlive(processes) do
        if processes == [] do # just end, do nothing
            "END"
        else
            if Process.alive?(hd(processes)) do 
                checkProcessAlive(processes)
            else
                checkProcessAlive(tl(processes))
            end
        end			
    end
end

