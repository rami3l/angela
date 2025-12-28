defmodule Angela.Command.APOD do
  @moduledoc """
  Fetches the Astronomy Picture of the Day from NASA's API.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters}
  require Logger

  @behaviour Angela.Command

  @impl true
  def usage, do: "/apod [YYYYMMDD]"

  @impl true
  def respond(msg = %Message{}) do
    case String.trim(msg.text) do
      "" ->
        Date.utc_today()

      term ->
        {:ok, erl} = Calendar.ISO.parse_date(term, :basic)
        Date.from_erl!(erl)
    end
    |> fetch_apod()
    |> case do
      {:ok, entry} -> response_text(entry)
      {:error, reason} -> "Oops, looks like I have encountered an error: #{inspect(reason)}"
    end
    |> Response.new(
      reply_parameters: %ReplyParameters{message_id: msg.message_id},
      parse_mode: "HTML"
    )
  end

  @api_endpoint "https://api.nasa.gov/planetary/apod"
  defp fetch_apod(date) do
    [
      date: Date.to_iso8601(date),
      api_key: Angela.Bot.get_env(:exn_tokens).nasa
    ]
    |> then(&Tesla.get(client(), @api_endpoint, query: &1))
    |> case do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} when is_bitstring(body) ->
        {:error, "HTTP #{status}: #{body}"}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp response_text(entry = %{"date" => date, "title" => title, "explanation" => details}) do
    """
    Here's the daily news from NASA:

    <blockquote expandable>
    <b>#{title}</b>, #{date}

    #{details}
    </blockquote>

    #{entry["hdurl"] || entry["url"] || ""}
    """
  end

  defp client, do: [Tesla.Middleware.JSON] |> Tesla.client()
end
