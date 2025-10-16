defmodule Angela.Command.EvalTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Eval

  alias Angela.Command.Eval
  alias ExGram.Model.Message

  import AssertMatch
  import Mox

  setup :verify_on_exit!

  describe "respond/1" do
    @respond &Eval.respond/1
    @msg_id %{message_id: 2048}

    defp msg(params), do: struct!(Message, params |> Map.merge(@msg_id))

    defp env(body, opts \\ []) do
      defaults = [status: 200]
      %{status: status} = Keyword.merge(defaults, opts) |> Enum.into(%{})
      %Tesla.Env{body: body, status: status}
    end

    test "responds with successful execution result" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert_match(env, %{method: :post, url: "https://play.rust-lang.org/execute"})
        assert {"Content-Type", "application/json"} in env.headers

        body = Jason.decode!(env.body)

        # Verify code wrapping for simple expression
        code = body["code"]
        assert code =~ ~r/println!\("\{:\?\}", \{/
        assert code =~ "21 + 21"

        %{
          "success" => true,
          "exitDetail" => "exit: 0",
          "stdout" => "42\n",
          "stderr" => ""
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "21 + 21"})
      |> @respond.()
      |> assert_match(%{
        text: """
        :) exit: 0

        STDOUT
        42

        STDERR
        """,
        opts: [reply_parameters: %{message_id: 2048}]
      })
    end

    test "responds with compilation error" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        %{
          "success" => false,
          "error" => "error[E0425]: cannot find value `invalid_variable` in this scope"
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "invalid_variable"})
      |> @respond.()
      |> assert_match(%{
        text: ":< error[E0425]: cannot find value `invalid_variable` in this scope",
        opts: [reply_parameters: %{message_id: 2048}]
      })
    end

    test "responds with runtime error" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        %{
          "success" => false,
          "exitDetail" => "exit: 101",
          "stdout" => "",
          "stderr" => "thread 'main' panicked at 'explicit panic'"
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: ~S[panic!("explicit panic")]})
      |> @respond.()
      |> assert_match(%{
        text: """
        :< exit: 101

        STDOUT

        STDERR
        thread 'main' panicked at 'explicit panic'\
        """,
        opts: [reply_parameters: @msg_id]
      })
    end

    test "handles HTTP error responses" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts -> {:ok, env("", status: 500)} end)

      msg(%{text: ~S[println!("test")]})
      |> @respond.()
      |> assert_match(%{text: ~S[error: "HTTP 500"], opts: [reply_parameters: @msg_id]})
    end

    test "handles network errors" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts -> {:error, :timeout} end)

      msg(%{text: ~S[println!("test")]})
      |> @respond.()
      |> assert_match(%{text: "error: :timeout", opts: [reply_parameters: @msg_id]})
    end

    test "handles unknown response format" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        %{"unknown_field" => "unknown_value"} |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "42"})
      |> @respond.()
      |> assert_match(%{text: ":< unknown response format", opts: [reply_parameters: @msg_id]})
    end

    test "handles empty error field in unsuccessful response" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        %{
          "success" => false,
          "error" => "",
          "exitDetail" => "exit: 1",
          "stdout" => "",
          "stderr" => "compilation failed\n"
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "invalid code"})
      |> @respond.()
      |> assert_match(%{
        text: """
        :< exit: 1

        STDOUT

        STDERR
        compilation failed
        """,
        opts: [reply_parameters: @msg_id]
      })
    end

    test "handles successful response with mixed stdout and stderr" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        %{
          "success" => true,
          "exitDetail" => "exit: 0",
          "stdout" => "Output line 1\nOutput line 2\n",
          "stderr" => "Warning: unused variable\n"
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: ~S[println!("test")]})
      |> @respond.()
      |> assert_match(%{
        text: """
        :) exit: 0

        STDOUT
        Output line 1
        Output line 2

        STDERR
        Warning: unused variable
        """,
        opts: [reply_parameters: %{message_id: 2048}]
      })
    end
  end

  describe "code wrapping behavior" do
    test "wraps simple expressions with println! and debug formatting" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        body = Jason.decode!(env.body)

        assert body["code"] == """
               #[allow(warnings)] fn main() -> Result<(), Box<dyn std::error::Error>> { println!("{:?}", {
               1 + 1
               }); Ok(()) }\
               """

        %{
          "success" => true,
          "exitDetail" => "exit: 0",
          "stdout" => "2\n",
          "stderr" => ""
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "1 + 1"}) |> @respond.()
    end

    test "wraps code with print statements in a block without debug formatting" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        body = Jason.decode!(env.body)

        assert body["code"] ==
                 """
                 #[allow(warnings)] fn main() -> Result<(), Box<dyn std::error::Error>> { {
                 println!("test")
                 }; Ok(()) }\
                 """

        %{
          "success" => true,
          "exitDetail" => "exit: 0",
          "stdout" => "test\n",
          "stderr" => ""
        }
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: ~S[println!("test")]}) |> @respond.()
    end

    test "verifies all request parameters are correctly set" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        body = Jason.decode!(env.body)

        assert_match(
          body,
          %{
            "crateType" => "bin",
            "channel" => "nightly",
            "edition" => "2024",
            "mode" => "debug",
            "tests" => false,
            "backtrace" => true,
            "code" => code
          }
          when is_binary(code)
        )

        %{"success" => true, "exitDetail" => "exit: 0", "stdout" => "", "stderr" => ""}
        |> then(&{:ok, env(&1)})
      end)

      msg(%{text: "42"}) |> @respond.()
    end
  end
end
