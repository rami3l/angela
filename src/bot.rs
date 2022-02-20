mod cmd;
use std::sync::Arc;

use teloxide::dispatching::update_listeners;
#[allow(clippy::wildcard_imports)]
use teloxide::{dispatching2::Dispatcher, prelude2::*};
use tracing::{debug, info};

pub(crate) async fn launch(token: impl Into<String>) {
    info!("Angela is waking up...");
    let bot = Bot::new(token.into()).auto_send();
    let handler = cmd::handle;
    let listener = update_listeners::polling_default(bot.clone()).await;

    let mut dispatcher = Dispatcher::builder(
        bot,
        Update::filter_message()
            .filter_command::<cmd::Command>()
            .branch(dptree::endpoint(handler)),
    )
    .default_handler(Box::new(|update: Arc<Update>| {
        debug!("Unhandled update of id {}", update.id);
        Box::pin(async {})
    }))
    .build();

    dispatcher
        .setup_ctrlc_handler()
        .dispatch_with_listener(
            listener,
            LoggingErrorHandler::with_custom_text("An error from the update listener"),
        )
        .await;
}
