defmodule Angela.Command.RustRelease do
  @moduledoc """
  Shows current and upcoming Rust release versions based on the 6-week release cycle.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters}

  @epoch ~D[2015-12-10]
  @epoch_release 5
  @date_fmt "%b %d %Y"

  @behaviour Angela.Command

  @impl true
  def usage(), do: "/rustrelease"

  @impl true
  def respond(msg = %Message{}) do
    # Convert Unix timestamp to Date
    now = msg.date |> DateTime.from_unix!() |> DateTime.to_date()

    # Based on https://forge.rust-lang.org/js/index.js
    stable = rust_v1_release(now)
    beta = rust_v1_release(Date.add(now, 7 * 6))
    nightly = rust_v1_release(Date.add(now, 7 * 6 * 2))
    next = rust_v1_release(Date.add(now, 7 * 6 * 3))

    """
    Oh, I just asked Ferris 🦀️...
    ```
    stable:\t#{stable}
    beta:\t#{beta}
    nightly:\t#{nightly}
    next:\t#{next}
    ```\
    """
    |> Response.new(
      reply_parameters: %ReplyParameters{message_id: msg.message_id},
      parse_mode: "Markdown"
    )
  end

  defp rust_v1_release(date) do
    date_str =
      (minor = date |> minor_version())
      |> release_date()
      |> Calendar.strftime(@date_fmt)

    "Rust v1.#{minor}\t(#{date_str})"
  end

  defp minor_version(date) do
    days = Date.diff(date, @epoch)

    if days >= 0 do
      weeks = div(days, 7)
      @epoch_release + div(weeks, 6)
    else
      -1
    end
  end

  defp release_date(minor_version) do
    new_releases = minor_version - @epoch_release
    Date.add(@epoch, new_releases * 6 * 7)
  end
end
