module Angela.Program

open ExtCore.Control.WorkflowBuilders
open Funogram.Api
open Funogram.Telegram.Api
open Funogram.Telegram.Bot

let onHello (context: UpdateContext) =
    // printfn $"Received update: {context.Update.UpdateId}"
    maybe {
        let! message = context.Update.Message
        let! name = message.Chat.FirstName

        $"Angela: Hi, {name}!"
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (fun e -> printfn $"Error: {e}")
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
    launch "bot-token" // TODO: Change this placeholder
    |> Async.RunSynchronously
    |> ignore // TODO: Process API responses somehow

    0
