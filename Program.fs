module Angela.Program

open ExtCore.Control.WorkflowBuilders
open Microsoft.FSharpLu.Logging
open Funogram.Api
open Funogram.Telegram.Api
open Funogram.Telegram.Bot

let onHello (context: UpdateContext) =
    Trace.info $"Triggered: /hello"
    Trace.info $"Received update: {context.Update.UpdateId}"

    maybe {
        let! message = context.Update.Message
        let! name = message.Chat.FirstName

        $"Angela: Hi, {name}!"
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (fun e -> Trace.warning $"Error while sending message: {e}")
        |> ignore
    }
    |> ignore

let onUpdate (context: UpdateContext) =
    processCommands context [ cmd "/hello" onHello ]
    |> ignore

let launch (token: string) : Async<unit> =
    startBot { defaultConfig with Token = token } onUpdate None

[<EntryPoint>]
let main (_: array<string>) : int =
    System.Diagnostics.Trace.Listeners.Add(new System.Diagnostics.ConsoleTraceListener())
    |> ignore

    launch "bot-token" // TODO: Change this placeholder
    |> Async.RunSynchronously
    |> ignore // TODO: Process API responses somehow

    0
