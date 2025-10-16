defmodule AngelaTest do
  use ExUnit.Case
  doctest Angela

  import AssertMatch

  test "has a version string" do
    Version.parse(Angela.version()) |> assert_match({:ok, _})
  end
end
