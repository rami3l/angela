defmodule Angela.Command.Eval do
  @moduledoc """
  Evaluates Rust code using the Rust Playground.
  """

  alias Angela.Command.Response
  alias ExGram.Model.{Message, ReplyParameters}

  @behaviour Angela.Command

  @impl true
  def usage(), do: "/eval <rust_code>"

  @impl true
  def respond(msg = %Message{text: src}) when src != "" do
    %{
      "crateType" => "bin",
      "channel" => "nightly",
      "edition" => "2024",
      "mode" => "debug",
      "tests" => false,
      "backtrace" => true,
      "code" => wrap_main(src)
    }
    |> query()
    |> case do
      {:ok, res} -> msg(res)
      {:error, reason} -> "error: #{inspect(reason)}"
    end
    |> Response.new(reply_parameters: %ReplyParameters{message_id: msg.message_id})
  end

  defp msg(result) do
    leader = if result["success"], do: ":)", else: ":<"

    case result do
      %{"success" => false, "error" => error} when error != "" ->
        "#{leader} #{error}"

      %{"exitDetail" => exit_detail, "stdout" => stdout, "stderr" => stderr} ->
        """
        #{leader} #{exit_detail}

        STDOUT
        #{stdout}
        STDERR
        #{stderr}\
        """

      _ ->
        "#{leader} unknown response format"
    end
  end

  @api_endpoint "https://play.rust-lang.org/execute"
  defp query(body) do
    case Tesla.post(client(), @api_endpoint, body) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp client() do
    [
      {Tesla.Middleware.Headers, [{"content-type", "application/json"}]},
      Tesla.Middleware.JSON
    ]
    |> Tesla.client()
  end

  defp wrap_main(src) do
    block =
      if src =~ ~r/print(ln)?!\(/ do
        "{\n#{src}\n};"
      else
        "println!(\"{:?}\", {\n#{src}\n});"
      end

    """
    #[allow(warnings)] fn main() -> Result<(), Box<dyn std::error::Error>> {
    #{block}
    \tOk(())
    }\
    """
  end
end
