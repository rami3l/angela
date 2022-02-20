use anyhow::Result;
use itertools::Itertools;
use rand::Rng;
#[allow(clippy::wildcard_imports)]
use teloxide::{prelude2::*, utils::command::BotCommand};
use tracing::info;

#[derive(BotCommand, Clone)]
#[command(rename = "lowercase", description = "These commands are supported:")]
pub(crate) enum Command {
    #[command(description = "Display this text.")]
    Help,
    #[command(description = "Say hello to Angela!")]
    Hello,
    #[command(description = "Doctor's orders!")]
    Decide(String),
}

pub(crate) async fn handle(bot: AutoSend<Bot>, msg: Message, command: Command) -> Result<()> {
    #[allow(clippy::enum_glob_use)]
    use Command::*;

    info!("Triggered on message: `{:?}`", msg.text());
    match command {
        Help => help(&bot, &msg).await,
        Hello => hello(&bot, &msg).await,
        Decide(options) => decide(&bot, &msg, &options).await,
    }
}

async fn help(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    bot.send_message(msg.chat.id, Command::descriptions())
        .await?;
    Ok(())
}

async fn hello(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    let title = msg.chat.first_name().unwrap_or("Hi");
    bot.send_message(msg.chat_id(), format!("{title}, I'm right beside you!"))
        .await?;
    Ok(())
}

async fn decide(bot: &AutoSend<Bot>, msg: &Message, options: &str) -> Result<()> {
    let options = options.split_whitespace().collect_vec();
    if options.is_empty() {
        bot.send_message(msg.chat_id(), "Emmm... What's on your mind?")
            .await?;
        return Ok(());
    }
    let rand_idx = rand::thread_rng().gen_range(0..options.len());
    let choice = options[rand_idx];
    bot.send_message(msg.chat_id(), format!("Emmm... I'd say {choice}."))
        .await?;
    Ok(())
}
