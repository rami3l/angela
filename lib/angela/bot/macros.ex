defmodule Angela.Bot.Macros do
  @moduledoc """
  Macros for simplifying bot command declarations.
  """

  @doc """
  Macro to simplify command declaration by generating the command/2, @impl, and handle/2 boilerplate.
  """
  defmacro defcommand(module, name, description) do
    command_atom = String.to_atom(name)

    quote do
      command(unquote(name), description: unquote(description))
      @impl ExGram.Handler
      def handle({:command, unquote(command_atom), msg}, cx),
        do: unquote(module) |> Angela.Bot.reply(cx, msg)
    end
  end
end
