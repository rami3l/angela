defmodule Angela.Command.Decide do
  @moduledoc """
  Helps the user make a random decision.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters}

  @behaviour Angela.Command

  @impl true
  def usage(), do: "/decide <choice1> <choice2> ..."

  @impl true
  def respond(msg = %Message{}) do
    ([_ | _] = String.split(msg.text))
    |> Enum.random()
    |> Response.new(reply_parameters: %ReplyParameters{message_id: msg.message_id})
  end
end
