defmodule Angela.Bot do
  @moduledoc """
  The bot's core properties and the registration of commands it can handle.
  """

  alias Angela.Command
  alias ExGram.Cnt
  alias ExGram.Model.{Message, ReplyParameters}

  import Angela.Bot.Macros

  def bot, do: :angela

  use ExGram.Bot,
    name: bot(),
    setup_commands: Application.get_env(:angela, :setup_commands, false)

  middleware(ExGram.Middleware.IgnoreUsername)

  @spec reply(module(), Cnt.t(), Message.t()) :: Cnt.t()
  def reply(cmd, cx, msg) do
    return = &answer(cx, &1, &2)

    try do
      resp = %Command.Response{} = cmd.respond(msg)
      return.(resp.text, resp.opts)
    rescue
      MatchError ->
        return.(
          "usage: " <> cmd.usage(),
          reply_parameters: %ReplyParameters{message_id: msg.message_id}
        )
    end
  end

  defcommand(Command.Hello, "hello", "👋")
  defcommand(Command.Decide, "decide", "🎲")
  defcommand(Command.RustRelease, "rustrelease", "🦀")
  defcommand(Command.Eval, "eval", "⚙️")
  defcommand(Command.Etymology, "etymology", "📖")
end
