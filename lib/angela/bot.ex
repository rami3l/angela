defmodule Angela.Bot do
  @bot :angela

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, cx) do
    cx |> answer("Hi!")
  end

  def handle({:command, :help, _msg}, cx) do
    cx |> answer("Here is your help:")
  end
end
