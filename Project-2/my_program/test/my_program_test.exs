defmodule MyProgramTest do
  use ExUnit.Case
  doctest MyProgram

  test "greets the world" do
    assert MyProgram.hello() == :world
  end
end
