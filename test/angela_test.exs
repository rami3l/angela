defmodule AngelaTest do
  use ExUnit.Case
  doctest Angela

  test "greets the world" do
    assert Angela.hello() == :world
  end
end
