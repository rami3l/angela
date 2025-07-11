defmodule Angela.Command.Hello do
  @moduledoc """
  Greets the user.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters, User}

  @behaviour Angela.Command

  @impl true
  def usage, do: "/hello"

  @impl true
  def respond(msg = %Message{from: sender = %User{}}) do
    name = sender.first_name || "Hi"

    "#{name}, I'm right beside you!"
    |> Response.new(reply_parameters: %ReplyParameters{message_id: msg.message_id})
  end
end
