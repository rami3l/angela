module Angela.Program

open Microsoft.FSharpLu.Logging
open FSharpPlus
open Funogram.Api
open Funogram.Telegram.Api
open Funogram.Telegram.Bot

let onHello (context: UpdateContext) =
    Trace.info $"Triggered: /hello"
    Trace.info $"Received update: {context.Update.UpdateId}"

    monad {
        let! message = context.Update.Message
        let! name = message.Chat.FirstName

        $"Angela: Hi, {name}!"
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (fun e -> Trace.warning $"while sending message: {e}")
        |> ignore
    }
    |> ignore

let onUpdate (context: UpdateContext) =
    processCommands context [ cmd "/hello" onHello ]
    |> ignore

let getToken () : Result<string, string> =
    let envVarName = "ANGELA_TELEGRAM_BOT_TOKEN"

    match System.Environment.GetEnvironmentVariable envVarName with
    | null -> Error $"while fetching bot token: environment variable {envVarName} not found"
    | token -> Ok token

let launch (token: string) : Async<unit> =
    startBot { defaultConfig with Token = token } onUpdate None

[<EntryPoint>]
let main (_: array<string>) : int =
    new System.Diagnostics.ConsoleTraceListener()
    |> System.Diagnostics.Trace.Listeners.Add
    |> ignore

    monad {
        let! token = getToken ()
        token |> launch |> Async.RunSynchronously
    }
    |> Result.mapError (fun e -> Trace.critical $"{e}")
    |> ignore

    0
