use anyhow::Result;
#[allow(clippy::wildcard_imports)]
use teloxide::{prelude2::*, utils::command::BotCommand};
use tracing::info;

#[derive(BotCommand, Clone)]
#[command(rename = "lowercase", description = "These commands are supported:")]
pub(crate) enum Command {
    #[command(description = "display this text.")]
    Help,
    #[command(description = "say hello to Angela!")]
    Hello,
}

pub(crate) async fn handle(bot: AutoSend<Bot>, msg: Message, command: Command) -> Result<()> {
    info!("Triggered on message: `{:?}`", msg.text());
    match command {
        Command::Help => {
            bot.send_message(msg.chat.id, Command::descriptions())
                .await?
        }
        Command::Hello => {
            let title = msg.chat.first_name().unwrap_or("Hi");
            bot.send_message(msg.chat_id(), format!("{title}, I'm right beside you!"))
                .await?
        }
    };
    Ok(())
}
