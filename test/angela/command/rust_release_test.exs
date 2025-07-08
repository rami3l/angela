defmodule Angela.Command.RustReleaseTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.RustRelease

  alias Angela.Command.RustRelease
  alias ExGram.Model.Message

  import AssertMatch

  describe "respond/1" do
    @respond &RustRelease.respond/1
    @msg_id %{message_id: 123}

    defp msg(params), do: struct!(Message, params |> Map.merge(@msg_id))

    test "returns a response with Rust release information" do
      msg(%{date: DateTime.to_unix(~U"2025-05-14 01:02:03Z")})
      |> @respond.()
      |> assert_match(%{opts: [reply_parameters: @msg_id, parse_mode: "Markdown"]})
      |> then(&Regex.scan(~r/Rust v1\.(\d+)/, &1.txt, capture: :all_but_first))
      |> assert_match([["86"], ["87"], ["88"], ["89"]])
    end
  end
end
