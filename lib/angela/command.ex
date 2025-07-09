defmodule Angela.Command do
  @moduledoc """
  The "raw" command handler agnostic to the bot implementation.
  """

  alias ExGram.Model.Message

  defmodule Response do
    @moduledoc """
    The response structure for a "raw" command handler.
    """

    @type t :: %__MODULE__{text: String.t(), opts: keyword()}
    defstruct text: "", opts: []

    def new(text, opts \\ []), do: %__MODULE__{text: text, opts: opts}
  end

  @callback usage() :: String.t()
  @callback respond(msg :: Message.t()) :: Response.t()
end
