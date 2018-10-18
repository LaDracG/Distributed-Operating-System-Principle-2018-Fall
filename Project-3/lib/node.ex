defmodule Node do
  use GenServer

  def init(state) do
    {:ok, state}
  end


  def start(predecessor, finger_table) do
    {:ok, pid} = GenServer.start_link(
                        __MODULE__,
                        %{
                            :predecessor => predecessor,
                            :successor => nil,
                            :finger_table => finger_table
                        }
                    )
      pid
  end
end
