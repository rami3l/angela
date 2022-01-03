module Angela.Program

open Angela.Commands
open FSharpPlus
open FSharpPlus.Data
open Funogram.Telegram.Bot
open Microsoft.FSharpLu.Logging
open System

let onUpdate (context: UpdateContext) =
    let update = context.Update
    let unwrap = Option.defaultValue "<?>"
    Trace.verbose $"[{update.UpdateId}] \t update received"

    monad {
        let! message = update.Message

        let name =
            message.From |>> (fun user -> user.FirstName)

        let txt = message.Text
        Trace.verbose $"[{update.UpdateId}] \t {unwrap name}: {unwrap txt}"
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
    new Essential.Diagnostics.ColoredConsoleTraceListener()
    |> Diagnostics.Trace.Listeners.Add
    |> ignore

    monad {
        let! token = getToken ()
        Trace.info "Angela is waking up..."
        token |> launch |> Async.RunSynchronously
    }
    |> either (konst 0) (fun e ->
        Trace.critical $"{e}"
        1)
