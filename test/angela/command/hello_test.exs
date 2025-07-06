defmodule Angela.Command.HelloTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Hello

  alias Angela.Command.Hello
  alias ExGram.Model.{Message, ReplyParameters, User}

  import AssertMatch

  test "responds with a greeting" do
    user = %User{first_name: "Alice"}

    %Message{from: user, message_id: 123}
    |> Hello.respond()
    |> assert_match(%{
      txt: "Alice, I'm right beside you!",
      opts: [reply_parameters: %ReplyParameters{message_id: 123}]
    })
  end

  test "responds with a default greeting when first name is missing" do
    user = %User{}

    %Message{from: user, message_id: 456}
    |> Hello.respond()
    |> assert_match(%{
      txt: "Hi, I'm right beside you!",
      opts: [reply_parameters: %ReplyParameters{message_id: 456}]
    })
  end
end
