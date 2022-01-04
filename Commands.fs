module Angela.Commands

open FSharpPlus
open Funogram.Api
open Funogram.Telegram.Api
open Funogram.Telegram.Bot
open Microsoft.FSharpLu.Logging
open System

let onHello (context: UpdateContext) =
    Trace.info $"Triggered: /hello"

    monad {
        let! message = context.Update.Message
        let! name = message.From |>> (fun user -> user.FirstName)

        $"{name}, I'm right beside you!"
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (tap (fun e -> Trace.warning $"while sending message: {e}"))
    }
    |> ignore

let onDecide (args: string) (context: UpdateContext) =
    Trace.info $"Triggered: /decide {args}"

    monad {
        let! message = context.Update.Message

        let! args =
            Some args
            |> Option.filter (not << String.IsNullOrEmpty)
            |> map (fun args -> args.Split ' ')

        let idx = Random().Next(args.Length)
        let item = args.[idx]

        $"Emmm... I'd say {item}."
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (tap (fun e -> Trace.warning $"while sending message: {e}"))
    }
    |> ignore


let commands =
    lazy
        ([ cmd "/hello" onHello
           cmdScan "/decide %s" onDecide ])
