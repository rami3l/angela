defmodule Angela.Command.Etymology do
  @moduledoc """
  Looks up etymology information from Wiktionary.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters}
  require Logger

  @behaviour Angela.Command

  @impl true
  def usage, do: "/etymology <term>"

  @impl true
  def respond(msg = %Message{}) do
    term = String.trim(msg.text)
    if term == "", do: raise(MatchError)

    case fetch_etymology(term) do
      {:ok, entries} when entries != [] ->
        response_text(term, entries)

      {:ok, []} ->
        "Let me look it up...\n\nOops, it seems that I can't find the etymology in #{wiktionary_page(term)} ..."

      {:error, :not_found} ->
        "Oops, looks like there isn't such a page in Wiktionary..."

      {:error, reason} ->
        "Oops, looks like I have encountered an error: #{inspect(reason)}"
    end
    |> Response.new(reply_parameters: %ReplyParameters{message_id: msg.message_id})
  end

  @api_endpoint "https://en.wiktionary.org/w/api.php"
  defp fetch_etymology(term) do
    [
      action: "query",
      format: "json",
      titles: term,
      prop: "extracts",
      explaintext: "",
      utf8: "1"
    ]
    |> then(&Tesla.get(client(), @api_endpoint, query: &1))
    |> case do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        parse_wiktionary(body)

      {:ok, %Tesla.Env{status: status, body: body}} when is_bitstring(body) ->
        {:error, "HTTP #{status}: #{body}"}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_wiktionary(body) do
    case body do
      %{"query" => %{"pages" => pages}} ->
        case pages |> Map.values() |> List.first() do
          %{"extract" => extract} when is_binary(extract) -> {:ok, extract_etymology(extract)}
          _ -> {:error, :not_found}
        end

      _ ->
        {:error, :invalid_response}
    end
  end

  defp extract_etymology(extract) do
    extract
    |> String.split("\n")
    |> Stream.unfold(&extract_entry/1)
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp extract_entry(lines) do
    with rest = [_ | _] <- skip_to_etymology(lines),
         {entry = [_ | _], rest} <- extract_entry_lines(rest) do
      entry
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.join("\n")
      |> then(&{&1, rest})
    else
      [] -> nil
      {[], rest} -> extract_entry(rest)
    end
  end

  defp skip_to_etymology(lines) do
    lines
    |> Stream.drop_while(&(not String.contains?(&1, "= Etymology")))
    |> Enum.drop(1)
  end

  defp extract_entry_lines(lines), do: extract_entry_lines(lines, [])

  defp extract_entry_lines([], acc), do: {Enum.reverse(acc), []}

  defp extract_entry_lines(lines = [line | rest], acc) do
    cond do
      # Stops at next major section, i.e. `==` or `===`.
      String.starts_with?(line, "=") -> {Enum.reverse(acc), lines}
      # Includes non-empty lines.
      String.trim(line) != "" -> extract_entry_lines(rest, [line | acc])
      # Skips empty lines but continue.
      true -> extract_entry_lines(rest, acc)
    end
  end

  @max_len 2000
  defp response_text(term, entries) do
    {body, _} =
      entries
      |> Stream.with_index(1)
      |> Enum.reduce_while({"", 0}, fn {entry, index}, {acc, len} ->
        item = "#{index}. #{entry}\n\n"
        len = len + String.length(item)

        if len >= @max_len,
          do: {:halt, {acc <> "...\n\n", len}},
          else: {:cont, {acc <> item, len}}
      end)

    "Let me look it up...\n\n#{term}:\n\n#{body}src: #{wiktionary_page(term)}"
  end

  defp wiktionary_page(term), do: "https://en.wiktionary.org/wiki/" <> URI.encode(term)

  defp client do
    [
      {Tesla.Middleware.Headers, [{"content-type", "application/json"}]},
      Tesla.Middleware.JSON
    ]
    |> Tesla.client()
  end
end
