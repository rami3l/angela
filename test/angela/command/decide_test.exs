defmodule Angela.Command.DecideTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Decide

  alias Angela.Command.Decide
  alias ExGram.Model.{Message, ReplyParameters}

  import AssertMatch

  describe "respond/1" do
    test "responds with the only choice" do
      %Message{text: " rice ", message_id: 123}
      |> Decide.respond()
      |> assert_match(%{
        txt: "rice",
        opts: [reply_parameters: %ReplyParameters{message_id: 123}]
      })
    end

    test "responds with one of the provided choices" do
      %Message{text: "pizza pasta burger", message_id: 456}
      |> Decide.respond()
      |> assert_match(
        %{
          txt: choice,
          opts: [reply_parameters: %ReplyParameters{message_id: 456}]
        }
        when choice in ["pizza", "pasta", "burger"]
      )
    end

    test "throws `MatchError` when no choices are provided" do
      MatchError
      |> assert_raise(fn -> Decide.respond(%Message{text: "", message_id: 789}) end)
    end
  end
end
