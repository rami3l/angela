defmodule Angela.Command do
  @moduledoc """
  The "raw" command handler agnostic to the bot implementation.
  """

  alias ExGram.Model.Message

  defmodule Response do
    @moduledoc """
    The response structure for a "raw" command handler.
    """

    @type t :: %__MODULE__{txt: String.t(), opts: keyword()}
    defstruct txt: "", opts: []

    def new(txt, opts \\ []), do: %__MODULE__{txt: txt, opts: opts}
  end

  @callback usage() :: String.t()
  @callback respond(msg :: Message.t()) :: Response.t()
end
