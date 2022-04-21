import argparse
import asyncio
import logging
import os
import random
from datetime import date, datetime

import coloredlogs
from aiogram import Bot, Dispatcher, executor
from aiogram.types.message import Message
from dotenv import load_dotenv

from angela.utils import RustV1Release, capture_redir


def main() -> None:
    load_dotenv()

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--token",
        default=os.environ.get("ANGELA_TELEGRAM_BOT_TOKEN"),
        help="the Telegram bot token to be used",
    )
    parser.add_argument(
        "-v", "--verbosity", action="count", help="the logging verbosity"
    )
    opts = parser.parse_args()

    verbosity = {
        1: logging.ERROR,
        2: logging.WARNING,
        3: logging.INFO,
        4: logging.DEBUG,
    }.get(opts.verbosity, logging.INFO)
    logging.basicConfig(level=verbosity)
    coloredlogs.install()

    logging.warning("Angela is waking up...")

    bot = Bot(token=opts.token)
    dp = Dispatcher(bot)

    dp.message_handler(commands="hello")(hello)
    dp.message_handler(commands="decide")(decide)
    dp.message_handler(commands="rustrelease")(rust_release)
    dp.message_handler(commands="randomwiki")(random_wiki)

    executor.start_polling(dp)


async def hello(msg: Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"👋 {title}, I'm right beside you!")


async def decide(msg: Message) -> None:
    formats = ["🤔 Emmm... I'd say {}.", "💡 What about {}?"]
    options = msg.text.split()[1:]
    if not options:
        title = (src := msg.from_user) and src.first_name or "Hi"
        await msg.reply(f"🤔 {title}, what's on your mind?")
        return
    await msg.reply(random.choice(formats).format(random.choice(options)))


async def rust_release(msg: Message) -> None:
    now: date = datetime.utcnow().date()
    stable = RustV1Release(now)
    beta = RustV1Release(now + RustV1Release.RELEASE_PERIOD)
    nightly = RustV1Release(now + 2 * RustV1Release.RELEASE_PERIOD)
    next_ = RustV1Release(now + 3 * RustV1Release.RELEASE_PERIOD)

    await msg.reply(
        parse_mode="MarkdownV2",
        text=f"""\
Oh, I just asked Ferris 🦀️:
```
stable: {stable}
beta: {beta}
nightly: {nightly}
next: {next_}
```
""",
    )


async def random_wiki(msg: Message) -> None:
    src = "commons.wikimedia.org"

    # Try splitting the text into [cmd, src]
    if len(txt := msg.text.split(maxsplit=1)) == 2:
        src = txt[1]

    prefixes = ["wiki/", "title/", ""]

    async def handle_prefix(prefix):
        endpoint = f"https://{src}/{prefix}Special:Random"
        return await capture_redir(endpoint)

    redirs = await asyncio.gather(*[handle_prefix(prefix) for prefix in prefixes])
    redir = next((r for r in redirs if r), None)

    if not redir:
        logging.info(f"/randomwiki: Cannot fetch random MediaWiki page at `{src}`")
        await msg.reply(
            """\
🤔 Oops... This doesn't seem like a MediaWiki site.

There are some working examples for you to try, though:
en.wiktionary.org
en.wikivoyage.org
wiki.archlinux.org
wiki.haskell.org
"""
        )
        return

    await msg.reply(
        f"""\
📖 (Paper fluttering...)
                    
Here you go!
{redir}
"""
    )


if __name__ == "__main__":
    main()
