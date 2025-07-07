defmodule Angela.Command.DecideTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Decide

  alias Angela.Command.Decide
  alias ExGram.Model.Message

  import AssertMatch

  describe "respond/1" do
    @respond &Decide.respond/1
    @msg_id %{message_id: 2048}

    defp msg(params), do: struct!(Message, params |> Map.merge(@msg_id))

    test "responds with the only choice" do
      msg(%{text: " rice "})
      |> @respond.()
      |> assert_match(%{
        txt: "rice",
        opts: [reply_parameters: @msg_id]
      })
    end

    test "responds with one of the provided choices" do
      msg(%{text: "pizza pasta burger"})
      |> @respond.()
      |> assert_match(
        %{txt: choice, opts: [reply_parameters: @msg_id]}
        when choice in ["pizza", "pasta", "burger"]
      )
    end

    test "throws `MatchError` when no choices are provided" do
      fn -> msg(%{text: ""}) |> @respond.() end
      |> then(&assert_raise(MatchError, &1))
    end
  end
end
