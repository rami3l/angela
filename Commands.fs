module Angela.Commands

open FSharpPlus
open FSharp.Data
open Funogram.Api
open Funogram.Telegram.Api
open Funogram.Telegram.Bot
open Microsoft.FSharpLu.Logging
open System
open System.Text.RegularExpressions
open System.Web

let sendText (context: UpdateContext) (text: string) =
    monad {
        let! message = context.Update.Message

        return!
            text
            |> sendMessage message.Chat.Id
            |> api context.Config
            |> Async.RunSynchronously
            |> Result.mapError (tap (fun e -> Trace.warning $"while sending message: {e}"))
            |> Option.ofResult
    }


let onHello (context: UpdateContext) =
    Trace.info $"Triggered: /hello"

    monad {
        let! name =
            context.Update.Message >>= (fun msg -> msg.From)
            |>> (fun user -> user.FirstName)

        return!
            $"{name}, I'm right beside you!"
            |> sendText context
    }
    |> ignore

let onDecide (args: string) (context: UpdateContext) =
    Trace.info $"Triggered: /decide {args}"

    monad {
        let! args =
            Some args
            |> Option.filter (not << String.IsNullOrWhiteSpace)
            |> map (fun args -> args.Split ' ')

        let idx = Random().Next(args.Length)
        let item = args.[idx]

        return! $"Emmm... I'd say {item}." |> sendText context
    }
    |> ignore

let onEtymology (args: string) (context: UpdateContext) =
    Trace.info $"Triggered: /etymology {args}"

    monad {
        let! message = context.Update.Message
        let endpoint = "https://en.wiktionary.org/w/api.php"

        let query =
            [ "action", "query"
              "format", "json"
              "titles", args
              "prop", "extracts"
              "explaintext", "" ]

        let result =
            Http.RequestString(endpoint, httpMethod = "GET", query = query)

        let matches =
            Regex(""" \"extract\":\"(.*)\" """.Trim())
                .Matches(result)

        let! extract =
            match matches with
            | m when m.Count <> 0 && m.[0].Groups.Count >= 1 -> Some m.[0].Groups.[1].Value
            | _ ->
                Trace.warning $"invalid wiktionary extract: {result}"

                $"Emmm... Is there really such a word?"
                |> sendText context
                |> ignore

                None
            |> map Regex.Unescape
            |> Option.filter (not << String.IsNullOrWhiteSpace)

        Trace.verbose $"/etymology: got extract `{extract}`"

        let firstEntry =
            extract
            |> String.split [ "\r\n"; "\r"; "\n" ]
            // ! Destructive operation! We only keep the first etymology...
            |> Seq.skipWhile (not << String.isSubString "= Etymology")
            |> Seq.skip 1
            |> Seq.takeWhile (not << String.startsWith "=")
            |> Seq.filter (not << String.IsNullOrWhiteSpace)
            |> curry String.Join "\n"

        Trace.info $"/etymology: got first entry `{firstEntry}`"

        let url =
            $"https://en.wiktionary.org/wiki/{HttpUtility.UrlEncode args}"

        return!
            $"Let me look it up...\n\n{args}:\n\n{firstEntry}\n\nsrc: {url}"
            |> sendText context
    }
    |> ignore


let commands =
    lazy
        ([ cmd "/hello" onHello
           cmdScan "/etymology %s" onEtymology
           cmdScan "/decide %s" onDecide ])
