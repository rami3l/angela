defmodule Angela.Bot do
  @moduledoc """
  The bot's core properties and the registration of commands it can handle.
  """

  alias ExGram.Cnt
  alias ExGram.Model.{Message, ReplyParameters}
  alias Angela.Command

  import Angela.Bot.Macros

  def bot(), do: :angela

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
