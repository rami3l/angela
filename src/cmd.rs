use anyhow::{anyhow, Context, Result};
use clap::Parser;
use clap_verbosity_flag::Verbosity;
use tracing_log::AsTrace;

use crate::bot;

/// The command line options to be collected.
#[derive(Debug, Parser)]
#[clap(
    version = clap::crate_version!(),
    author = clap::crate_authors!(),
    about = clap::crate_description!(),
)]
#[allow(clippy::struct_excessive_bools)]
pub struct Angela {
    /// The logging verbosity.
    #[clap(flatten)]
    verbose: Verbosity,

    #[clap(long, env = "ANGELA_TELEGRAM_BOT_TOKEN")]
    token: Option<String>,
}

impl Angela {
    pub async fn launch() -> Result<()> {
        drop(dotenv::dotenv());
        Self::parse().dispatch().await
    }

    pub(crate) async fn dispatch(self) -> Result<()> {
        tracing_subscriber::fmt()
            .with_max_level(self.verbose.log_level().map(|l| l.as_trace()))
            .init();
        bot::launch(self.token.with_context(|| anyhow!("bot token not found"))?).await;
        Ok(())
    }
}
