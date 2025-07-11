defmodule Angela.Command.EtymologyTest do
  use ExUnit.Case, async: true
  doctest Angela.Command.Etymology

  alias Angela.Command.Etymology
  alias Angela.Command.Response
  alias ExGram.Model.Message

  import AssertMatch
  import Mox

  setup :verify_on_exit!

  describe "respond/1" do
    @respond &Etymology.respond/1
    @msg_id %{message_id: 2048}

    defp msg(params), do: struct!(Message, params |> Map.merge(@msg_id))

    defp env(body, opts \\ []) do
      defaults = [status: 200]
      %{status: status} = Keyword.merge(defaults, opts) |> Enum.into(%{})
      %Tesla.Env{body: body, status: status}
    end

    test "responds with etymology entries when found" do
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "extract" => """
              == English ==

              === Etymology 1 ===
              Attested since the 16th century; borrowed from Scots wow.

              ==== Pronunciation ====
              enPR: wou, IPA(key): /waʊ̯/

              === Etymology 2 ===
              Imitative.

              ==== Noun ====
              wow (countable and uncountable, plural wows)
              """
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert_match(env, %{method: :get, url: "https://en.wiktionary.org/w/api.php"})
        assert {"content-type", "application/json"} in env.headers

        env.query
        |> assert_match(
          action: "query",
          format: "json",
          titles: "wow",
          prop: "extracts",
          explaintext: "",
          utf8: "1"
        )

        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "wow"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text == """
             Let me look it up...

             wow:

             1. Attested since the 16th century; borrowed from Scots wow.

             2. Imitative.

             src: https://en.wiktionary.org/wiki/wow\
             """
    end

    test "responds with not found message when word is missing" do
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "-1" => %{
              "missing" => ""
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "nonexistentword"})
      |> @respond.()
      |> assert_match(%Response{
        text: "Oops, looks like there isn't such a page in Wiktionary...",
        opts: [reply_parameters: @msg_id]
      })
    end

    test "responds with not found message when no extract available" do
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "title" => "someword"
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "someword"})
      |> @respond.()
      |> assert_match(%Response{
        text: "Oops, looks like there isn't such a page in Wiktionary...",
        opts: [reply_parameters: @msg_id]
      })
    end

    test "responds with no etymology message when no etymology sections found" do
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "extract" => """
              == English ==

              ==== Pronunciation ====
              enPR: wou, IPA(key): /waʊ̯/

              ==== Noun ====
              A word without etymology section.
              """
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "word"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ "Let me look it up..."

      assert text =~
               "Oops, it seems that I can't find the etymology in https://en.wiktionary.org/wiki/word ..."
    end

    test "handles HTTP error responses" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts -> {:ok, env("", status: 500)} end)

      msg(%{text: "test"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ "Oops, looks like I have encountered an error:"
    end

    test "handles network errors" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts -> {:error, :timeout} end)

      msg(%{text: "test"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ "Oops, looks like I have encountered an error:"
    end

    test "handles invalid JSON response" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env("invalid json")}
      end)

      msg(%{text: "test"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ "Oops, looks like I have encountered an error:"
    end

    test "truncates long responses to fit message limit" do
      long_etymology = String.duplicate("Very long etymology text. ", 100)

      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "extract" => """
              == English ==

              === Etymology 1 ===
              #{long_etymology}

              === Etymology 2 ===
              #{long_etymology}

              === Etymology 3 ===
              #{long_etymology}
              """
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "longword"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ "Let me look it up..."
      assert text =~ "longword:"
      assert text =~ "..."
      # Should be truncated
      assert String.length(text) < 2500
    end

    test "handles multiple etymology sections correctly" do
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "extract" => """
              == English ==

              === Etymology 1 ===
              First etymology entry.

              ==== Pronunciation ====
              Some pronunciation info.

              === Etymology 2 ===
              Second etymology entry.

              == Polish ==

              === Etymology ===
              Polish etymology entry.
              """
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "multiword"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ """
             1. First etymology entry.

             2. Second etymology entry.

             3. Polish etymology entry.
             """
    end
  end

  describe "etymology extraction" do
    test "extracts etymology from sample text" do
      sample_text = """


      == English ==


      === Etymology 1 ===
      Attested since the 16th century; borrowed from Scots wow.


      ==== Pronunciation ====
      enPR: wou, IPA(key): /waʊ̯/

      Rhymes: -aʊ


      ==== Interjection ====
      wow

      An indication of excitement, surprise, astonishment, or pleasure.
      1513, Gavin Douglas, Virgil Æneid (translation) vi. Prol. 19:
      Out on thir wanderand spiritis, wow! thow cryis.
      An expression of amazement, awe, or admiration.

      Used sarcastically to express disapproval of something.


      ===== Synonyms =====
      See also Thesaurus:wow


      ===== Derived terms =====


      ===== Translations =====


      ==== Verb ====
      wow (third-person singular simple present wows, present participle wowing, simple past and past participle wowed)

      (transitive, informal) To amaze or awe.


      ===== Translations =====


      ==== Noun ====
      wow (plural wows)

      (informal) Anything exceptionally surprising, unbelievable, outstanding, etc.

      1991, Stephen Fry, The Liar, p. 27:
      ‘Jesus suffering fuck,’ said Adrian. ‘It's not half a thought.’¶ ‘Face it, it's a wow.’


      ===== Derived terms =====
      wowless


      === Etymology 2 ===
      Imitative.


      ==== Noun ====
      wow (countable and uncountable, plural wows)

      (audio) A relatively slow form of flutter (pitch variation) which can affect both gramophone records and tape recorders.
      1970, Larry G. Goodwin, ‎Thomas Koehring, Closed-circuit Television Production Techniques (page 80)
      Sound films have to be loaded so that the sound is 5 seconds before the sound drum so a wow does not result when the film is punched up on the air.


      === Anagrams ===
      oww


      == Atikamekw ==


      === Noun ===
      wow

      egg


      == Middle English ==


      === Noun ===
      wow

      Alternative form of wowe


      == Polish ==


      === Etymology ===
      From English wow.


      === Pronunciation ===
      IPA(key): /waw/


      === Interjection ===
      wow

      (colloquial, slang, informal) wow


      === Further reading ===
      wow in Wielki słownik języka polskiego, Instytut Języka Polskiego PAN
      wow in Polish dictionaries at PWN


      == Spanish ==


      === Etymology ===
      Unadapted borrowing from English wow.


      === Pronunciation ===
      IPA(key): /ˈwau/, [ˈwau̯]


      === Interjection ===
      wow

      wow (an indication of excitement or surprise)


      ==== Usage notes ====
      According to Royal Spanish Academy (RAE) prescriptions, unadapted foreign words should be written in italics in a text printed in roman type, and vice versa, and in quotation marks in a manuscript text or when italics are not available. In practice, this RAE prescription is not always followed.
      """

      # We can't directly test the private function, but we can test through the public interface
      wiktionary_response = %{
        "query" => %{
          "pages" => %{
            "12345" => %{
              "extract" => sample_text
            }
          }
        }
      }

      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok, env(wiktionary_response)}
      end)

      msg(%{text: "test"})
      |> @respond.()
      |> assert_match(%Response{text: text, opts: [reply_parameters: @msg_id]})

      assert text =~ """
             1. Attested since the 16th century; borrowed from Scots wow.

             2. Imitative.

             3. From English wow.

             4. Unadapted borrowing from English wow.
             """
    end
  end
end
