use std::fmt::{self, Display};

use anyhow::{Context, Result};
#[allow(clippy::wildcard_imports)]
use futures::prelude::*;
use indoc::indoc;
use itertools::Itertools;
use once_cell::sync::Lazy;
use rand::Rng;
use regex::Regex;
use tap::Pipe;
use teloxide::types::ParseMode;
#[allow(clippy::wildcard_imports)]
use teloxide::{prelude2::*, utils::command::BotCommand};
use time::{
    format_description::{self, FormatItem},
    Date, Duration, Month, OffsetDateTime,
};
use tracing::{debug, info, warn};

use super::utils::{capture_redir, unescape, urlencode};

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
    #[command(description = "📖")]
    Etymology(String),
    #[command(description = "❓")]
    RandomWiki(String),
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
        RandomWiki(src) => random_wiki(&bot, &msg, &src).await,
    }
}

async fn help(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    bot.send_message(msg.chat.id, Command::descriptions())
        .await?;
    Ok(())
}

async fn hello(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    let title = msg
        .from()
        .map(|src| &src.first_name as &str)
        .filter(|s| !s.is_empty())
        .unwrap_or("Hi");
    bot.send_message(msg.chat.id, format!("{title}, I'm right beside you!"))
        .await?;
    Ok(())
}

async fn decide(bot: &AutoSend<Bot>, msg: &Message, options: &str) -> Result<()> {
    let options = options.split_whitespace().collect_vec();
    if options.is_empty() {
        let title = msg
            .from()
            .map(|src| &src.first_name as &str)
            .filter(|s| !s.is_empty())
            .unwrap_or("My friend");
        bot.send_message(msg.chat.id, format!("{title}, what's on your mind?"))
            .await?;
        return Ok(());
    }
    let rand_idx = rand::thread_rng().gen_range(0..options.len());
    let choice = options[rand_idx];
    bot.send_message(msg.chat.id, format!("Emmm... I'd say {choice}."))
        .await?;
    Ok(())
}

async fn rust_release(bot: &AutoSend<Bot>, msg: &Message) -> Result<()> {
    struct RustV1Release(Date);

    impl RustV1Release {
        const EPOCH_MINOR: i64 = 5;

        fn epoch() -> Date {
            static EPOCH: Lazy<Date> =
                Lazy::new(|| Date::from_calendar_date(2015, Month::December, 10).unwrap());
            *EPOCH
        }

        fn minor(&self) -> i64 {
            let weeks_since_epoch = (self.0 - Self::epoch()).whole_weeks();
            if weeks_since_epoch < 0 {
                return -1;
            }
            let new_minors = weeks_since_epoch / 6;
            Self::EPOCH_MINOR + new_minors
        }

        fn release_date(&self) -> Date {
            let new_minors = self.minor() - Self::EPOCH_MINOR;
            Self::epoch() + Duration::weeks(new_minors * 6)
        }
    }

    impl Display for RustV1Release {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            static FORMAT: Lazy<Vec<FormatItem>> =
                Lazy::new(|| format_description::parse("[month repr:short] [day] [year]").unwrap());
            f.write_fmt(format_args!(
                "Rust v1.{}\t({})",
                self.minor(),
                self.release_date().format(&*FORMAT).unwrap(),
            ))
        }
    }

    let now = OffsetDateTime::now_utc().date();
    let stable = RustV1Release(now);
    let beta = RustV1Release(now + Duration::weeks(6));
    let nightly = RustV1Release(now + Duration::weeks(2 * 6));
    let next = RustV1Release(now + Duration::weeks(3 * 6));

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
    )
    .pipe(|txt| {
        bot.parse_mode(ParseMode::MarkdownV2)
            .send_message(msg.chat.id, txt)
    })
    .await?;
    Ok(())
}

async fn etymology(bot: &AutoSend<Bot>, msg: &Message, keywords: &str) -> Result<()> {
    if keywords.is_empty() {
        let title = msg
            .from()
            .map(|src| &src.first_name as &str)
            .filter(|s| !s.is_empty())
            .unwrap_or("My friend");
        bot.send_message(msg.chat.id, format!("{title}, what's on your mind?"))
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
        bot.send_message(msg.chat.id, "Emmm... Is there really such a word?")
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
        format!(
            indoc! {"
                Let me look it up...
                
                Oops, it seems that I can't find the etymology in {}...
            "},
            source,
        )
        .pipe(|txt| bot.send_message(msg.chat.id, txt))
        .await?;
    } else {
        info!("/etymology: Got first entry `{first_entry}`");
        format!(
            indoc! {"
                Let me look it up...
                
                {}:

                {}

                src: {}
            "},
            keywords, first_entry, source,
        )
        .pipe(|txt| bot.send_message(msg.chat.id, txt))
        .await?;
    }
    Ok(())
}

async fn random_wiki(bot: &AutoSend<Bot>, msg: &Message, mut src: &str) -> Result<()> {
    if src.is_empty() {
        src = "commons.wikimedia.org";
    }

    let prefixes = &["wiki/", "title/", ""];
    let url = prefixes
        .iter()
        .map(|prefix| {
            async move {
                let endpoint = format!("https://{src}/{prefix}Special:Random");
                let redirected = capture_redir(&endpoint).await?;
                (endpoint.to_lowercase() != redirected.to_lowercase())
                    .then(|| {
                        info!("/randomwiki: Detected redirection `{endpoint}` -> `{redirected}`");
                        redirected
                    })
                    .context("no redirection detected")
            }
            .pipe(Box::pin)
        })
        .pipe(future::select_ok)
        .await;
    url.map_or_else(
        |err| {
            info!("/randomwiki: Cannot fetch random MediaWiki page: {err}");
            indoc! {"
                Oops... This doesn't seem like a MediaWiki site.

                There are some working examples for you to try, though:
                en.wiktionary.org
                en.wikivoyage.org
                wiki.archlinux.org
                wiki.haskell.org
            "}
            .into()
        },
        |(url, _)| {
            format!(
                indoc! {"
                    (Paper fluttering...)
                    
                    Here you go!
                    {}
                "},
                url,
            )
        },
    )
    .pipe(|txt| bot.send_message(msg.chat.id, txt))
    .await?;
    Ok(())
}
