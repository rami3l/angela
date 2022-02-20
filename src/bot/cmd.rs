use std::fmt::Display;

use anyhow::Result;
use chrono::{Date, Duration, NaiveDate, Utc};
use indoc::indoc;
use itertools::Itertools;
use rand::Rng;
use regex::Regex;
use teloxide::types::ParseMode;
#[allow(clippy::wildcard_imports)]
use teloxide::{prelude2::*, utils::command::BotCommand};
use tracing::{debug, info, warn};

use crate::bot::utils::{unescape, urlencode};

#[derive(BotCommand, Clone)]
#[command(rename = "lowercase", description = "These commands are supported:")]
pub(crate) enum Command {
    #[command(description = "Display this text.")]
    Help,
    #[command(description = "Say hello to Angela!")]
    Hello,
    #[command(description = "Doctor's orders!")]
    Decide(String),
    #[command(description = "🦀️")]
    RustRelease,
    #[command(description = "Doctor's orders!")]
    Etymology(String),
}

pub(crate) async fn handle(bot: AutoSend<Bot>, msg: Message, command: Command) -> Result<()> {
    #[allow(clippy::enum_glob_use)]
    use Command::*;

    info!("Triggered on message: `{:?}`", msg.text());
    match command {
        Help => help(&bot, &msg).await,
        Hello => hello(&bot, &msg).await,
        Decide(options) => decide(&bot, &msg, &options).await,
        RustRelease => rust_release(&bot, &msg).await,
        Etymology(query) => etymology(&bot, &msg, &query).await,
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
        let title = msg.chat.first_name().unwrap_or("My friend");
        bot.send_message(msg.chat_id(), format!("{title}, what's on your mind?"))
            .await?;
        return Ok(());
    }
    let rand_idx = rand::thread_rng().gen_range(0..options.len());
    let choice = options[rand_idx];
    bot.send_message(msg.chat_id(), format!("Emmm... I'd say {choice}."))
        .await?;
    Ok(())
}

async fn rust_release(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    struct RustV1Release(Date<Utc>);

    impl RustV1Release {
        const EPOCH_MINOR: i64 = 5;
        const DATE_FORMAT: &'static str = "%b %e %Y";

        fn epoch() -> Date<Utc> {
            Date::from_utc(NaiveDate::from_ymd(2015, 12, 10), Utc)
        }

        fn minor(&self) -> i64 {
            let weeks_since_epoch = self.0.signed_duration_since(Self::epoch()).num_weeks();
            if weeks_since_epoch < 0 {
                return -1;
            }
            let new_minors = weeks_since_epoch / 6;
            Self::EPOCH_MINOR + new_minors
        }

        fn release_date(&self) -> Date<Utc> {
            let new_minors = self.minor() - Self::EPOCH_MINOR;
            Self::epoch() + Duration::weeks(new_minors * 6)
        }
    }

    impl Display for RustV1Release {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.write_fmt(format_args!(
                "Rust v1.{}\t({})",
                self.minor(),
                self.release_date().format(Self::DATE_FORMAT),
            ))
        }
    }

    let now = Utc::now().date();
    let stable = RustV1Release(now);
    let beta = RustV1Release(now + Duration::weeks(6));
    let nightly = RustV1Release(now + Duration::weeks(2 * 6));
    let next = RustV1Release(now + Duration::weeks(3 * 6));

    bot.parse_mode(ParseMode::MarkdownV2)
        .send_message(
            msg.chat_id(),
            format!(
                indoc! {r#"
                Oh, I just asked Ferris 🦀️:

                ```
                stable: {}
                beta: {}
                nightly: {}
                next: {}
                ```
            "#},
                stable, beta, nightly, next,
            ),
        )
        .await?;
    Ok(())
}

async fn etymology(bot: &AutoSend<Bot>, msg: &Message, keywords: &str) -> Result<()> {
    if keywords.is_empty() {
        let title = msg.chat.first_name().unwrap_or("My friend");
        bot.send_message(msg.chat_id(), format!("{title}, what's on your mind?"))
            .await?;
        return Ok(());
    }

    let endpoint = "https://en.wiktionary.org/w/api.php";
    let query = &[
        ("action", "query"),
        ("format", "json"),
        ("titles", keywords),
        ("prop", "extracts"),
        ("explaintext", ""),
    ];

    let resp = reqwest::Client::new()
        .get(endpoint)
        .query(query)
        .send()
        .await?;
    let resp_txt = resp.text().await?;

    let pat = Regex::new(r#""extract":"(.*)""#)?;
    let captures = pat.captures(&resp_txt).filter(|c| c.len() >= 1);
    if captures.is_none() {
        info!("/etymology: Wiktionary extract not found");
        bot.send_message(msg.chat_id(), "Emmm... Is there really such a word?")
            .await?;
        return Ok(());
    }
    let raw_extract = captures.and_then(|c| c.get(1)).map_or("", |s| s.as_str());
    info!("/etymology: Got raw extract `{raw_extract}`");
    let extract = unescape(raw_extract);
    if extract.is_err() {
        warn!("/etymology: Error unescaping extract `{raw_extract}`");
    }
    let extract = extract.unwrap();
    debug!("/etymology: Got extract `{extract}`");

    let first_entry = extract
        .lines()
        // ! Destructive operation! We only keep the first etymology...
        .skip_while(|ln| !ln.contains("= Etymology"))
        .skip(1)
        .take_while(|ln| !ln.starts_with('='))
        .map(str::trim)
        .filter(|ln| !ln.is_empty())
        .join("\n");
    let first_entry = first_entry.trim();

    let source = format!("https://en.wiktionary.org/wiki/{}", urlencode(keywords));

    if first_entry.is_empty() {
        info!("/etymology: No etymology entries found");
        bot.send_message(
            msg.chat_id(),
            format!(
                indoc! {"
                    Let me look it up...
                    
                    Oops, it seems that I can't find the etymology in {}...
                "},
                source,
            ),
        )
        .await?;
    } else {
        info!("/etymology: Got first entry `{first_entry}`");
        bot.send_message(
            msg.chat_id(),
            &format!(
                indoc! {"
                        Let me look it up...
                        
                        {}:

                        {}

                        src: {}
                    "},
                keywords, first_entry, source,
            ),
        )
        .await?;
    }
    Ok(())
}
