use angela::Angela;
use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    Angela::launch().await
}
