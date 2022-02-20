use anyhow::Result;
#[allow(clippy::wildcard_imports)]
use teloxide::prelude2::*;
use tracing::info;

pub(crate) async fn launch(token: impl Into<String>) -> Result<()> {
    info!("Angela is waking up...");
    let bot = Bot::new(token.into()).auto_send();

    teloxide::repls2::repl(bot, |message: Message, bot: AutoSend<Bot>| async move {
        bot.send_dice(message.chat.id).await?;
        respond(())
    })
    .await;

    Ok(())
}
