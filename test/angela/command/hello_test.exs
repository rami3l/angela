defmodule Angela.Command.HelloTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Hello

  alias Angela.Command.Hello
  alias ExGram.Model.{Message, User}

  import AssertMatch

  describe "respond/1" do
    @respond &Hello.respond/1
    @msg_id %{message_id: 2048}

    defp msg(params), do: struct!(Message, params |> Map.merge(@msg_id))

    test "responds with the provided first name" do
      msg(%{from: %User{first_name: "Alice"}})
      |> @respond.()
      |> assert_match(%{
        txt: "Alice, I'm right beside you!",
        opts: [reply_parameters: @msg_id]
      })
    end

    test "responds with the default greeting when first name is missing" do
      msg(%{from: %User{}})
      |> @respond.()
      |> assert_match(%{
        txt: "Hi, I'm right beside you!",
        opts: [reply_parameters: @msg_id]
      })
    end
  end
end
