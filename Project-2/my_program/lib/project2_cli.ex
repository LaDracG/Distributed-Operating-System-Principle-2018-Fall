defmodule Project2.CLI do
  def main(args \\ []) do
    {opts, word, _} =
      OptionParser.parse(args, switches: [])
    IO.puts inspect(word)
  end

end