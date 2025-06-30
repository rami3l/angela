defmodule Angela.Bot do
  @moduledoc """
  The bot's core properties and the registration of commands it can handle.
  """

  alias ExGram.{Cnt, Model.Message}
  alias Angela.Command.{Hello, Response}

  @bot :angela

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  @spec reply(module(), Cnt.t(), Message.t()) :: Cnt.t()
  def reply(cmd, cx, msg) do
    resp = %Response{} = cmd.respond(msg)
    answer(cx, resp.txt, resp.opts)
  end

  command("hello", description: "👋")
  @impl ExGram.Handler
  def handle({:command, :hello, msg}, cx), do: Hello |> reply(cx, msg)
end
