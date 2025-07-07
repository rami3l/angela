defmodule Angela.Command.HelloTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Hello

  alias Angela.Command.Hello
  alias ExGram.Model.{Message, ReplyParameters, User}

  import AssertMatch

  describe "respond/1" do
    test "responds with the provided first name" do
      %Message{from: %User{first_name: "Alice"}, message_id: 123}
      |> Hello.respond()
      |> assert_match(%{
        txt: "Alice, I'm right beside you!",
        opts: [reply_parameters: %ReplyParameters{message_id: 123}]
      })
    end

    test "responds with the default greeting when first name is missing" do
      %Message{from: %User{}, message_id: 456}
      |> Hello.respond()
      |> assert_match(%{
        txt: "Hi, I'm right beside you!",
        opts: [reply_parameters: %ReplyParameters{message_id: 456}]
      })
    end
  end
end
