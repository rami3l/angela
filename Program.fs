module Angela.Program

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

        let! name =
            message.From
            |> Option.map (fun user -> user.FirstName)

        $"{name}, I'm right beside you!"
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (fun e -> Trace.warning $"while sending message: {e}")
        |> ignore
    }
    |> ignore

let onDecide (args: string) (context: UpdateContext) =
    Trace.info $"Triggered: /decide {args}"

    monad {
        let! message = context.Update.Message

        let! args =
            if args |> String.IsNullOrEmpty then
                None
            else
                args.Split ' ' |> Some

        let idx = Random().Next(args.Length)
        let item = args.[idx]

        $"Emmm... I'd say {item}."
        |> sendMessage message.Chat.Id
        |> api context.Config
        |> Async.RunSynchronously
        |> Result.mapError (fun e -> Trace.warning $"while sending message: {e}")
        |> ignore
    }
    |> ignore

let commands =
    lazy
        ([ cmd "/hello" onHello
           cmdScan "/decide %s" onDecide ])

let onUpdate (context: UpdateContext) =
    let update = context.Update
    let unwrap = Option.defaultValue "<?>"
    Trace.verbose $"[{update.UpdateId}] \t update received"

    monad {
        let! message = update.Message

        let name =
            message.From
            |> Option.map (fun user -> user.FirstName)
            |> unwrap

        let txt = message.Text |> unwrap
        Trace.verbose $"[{update.UpdateId}] \t {name}: {txt}"
    }
    |> ignore

    processCommands context commands.Value |> ignore

let getToken () : Result<string, string> =
    let envVarName = "ANGELA_TELEGRAM_BOT_TOKEN"

    match Environment.GetEnvironmentVariable envVarName with
    | null -> Error $"while fetching bot token: environment variable {envVarName} not found"
    | token -> Ok token

let launch (token: string) : Async<unit> =
    startBot { defaultConfig with Token = token } onUpdate None

[<EntryPoint>]
let main (_: array<string>) : int =
    new Diagnostics.ConsoleTraceListener()
    |> Diagnostics.Trace.Listeners.Add
    |> ignore

    monad {
        let! token = getToken ()
        Trace.info "Angela is waking up..."
        token |> launch |> Async.RunSynchronously
    }
    |> Result.mapError (fun e -> Trace.critical $"{e}")
    |> ignore

    0
