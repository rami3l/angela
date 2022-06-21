import argparse
import asyncio
import logging
import os
import random
import textwrap
from datetime import date, datetime
from urllib.parse import urlparse

import coloredlogs
import duckduckgo
import iso639
import langdetect
import wiktionaryparser as wiktionary
from aiogram import Bot, Dispatcher, executor
from aiogram.types.message import Message
from aiohttp import ClientConnectorError
from dotenv import load_dotenv

from angela.utils import RustV1Release, capture_redir, urldecode, urlencode

CMD_OPTION_PREFIX = "%"


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

    dp = Dispatcher(Bot(token=opts.token))

    dp.message_handler(commands="ddg")(ddg)
    dp.message_handler(commands="decide")(decide)
    dp.message_handler(commands="etymology")(etymology)
    dp.message_handler(commands="hello")(hello)
    dp.message_handler(commands="help")(help)
    dp.message_handler(commands="randomwiki")(random_wiki)
    dp.message_handler(commands="rustrelease")(rust_release)

    executor.start_polling(dp)


async def help(msg: Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"🤔 {title}, what's on your mind?")


async def hello(msg: Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"👋 {title}, I'm right beside you!")


async def ddg(msg: Message) -> None:
    if len(txt := msg.text.split(maxsplit=1)) != 2:
        await help(msg)
        return
    kw = txt[1]
    res = await asyncio.to_thread(lambda: duckduckgo.get_zci(kw))
    await msg.reply(
        textwrap.dedent(
            f"""\
            🦆 Quack! Quack!

            {res}
            """
        )
    )


async def decide(msg: Message) -> None:
    options = msg.text.split()[1:]
    if not options:
        await help(msg)
        return
    formats = ["🤔 Emmm... I'd say {}.", "💡 What about {}?"]
    await msg.reply(random.choice(formats).format(random.choice(options)))


async def rust_release(msg: Message) -> None:
    now: date = datetime.utcnow().date()
    [stable, beta, nightly, next_] = [
        RustV1Release(now + i * RustV1Release.RELEASE_PERIOD) for i in range(4)
    ]

    await msg.reply(
        parse_mode="MarkdownV2",
        text=textwrap.dedent(
            f"""\
            Oh, I just asked Ferris 🦀️:
            ```
            stable: {stable}
            beta: {beta}
            nightly: {nightly}
            next: {next_}
            ```
            """
        ),
    )


async def random_wiki(msg: Message) -> None:
    srcs = [
        "en.wikipedia.org",
        "en.wikisource.org",
        "en.wiktionary.org",
        "en.wikivoyage.org",
        "en.wikibooks.org",
        "en.wikiquote.org",
        "zh.wikipedia.org",
        "zh.wikisource.org",
        "zh.wiktionary.org",
        "zh.wikivoyage.org",
        "zh.wikibooks.org",
        "zh.wikiquote.org",
        "commons.wikimedia.org",
        "species.wikimedia.org",
        "evangelion.fandom.com",
        "wiki.archlinux.org",
        "wiki.haskell.org",
    ]
    src = random.choice(srcs)
    category = None

    # Try splitting the text into [cmd, src]
    if len(txt := msg.text.split(maxsplit=1)) == 2:
        src = txt[1]
    if src.startswith(CMD_OPTION_PREFIX) and len(txt := src.split(maxsplit=1)) == 2:
        [category, src] = txt
        category = category.lstrip(CMD_OPTION_PREFIX)

    prefixes = ["wiki/", "title/", ""]
    suffix = (
        f"Special:RandomInCategory/{urlencode(category)}"
        if category
        else "Special:Random"
    )

    async def handle_prefix(prefix):
        endpoint = f"https://{src}/{prefix}{suffix}"
        return await capture_redir(endpoint)

    try:
        redirs = await asyncio.gather(*map(handle_prefix, prefixes))
        redir: str = next(filter(None, redirs))
    except (StopIteration, ClientConnectorError):
        logging.info(f"/randomwiki: Cannot fetch random MediaWiki page at `{src}`")
        await msg.reply(
            textwrap.dedent(
                """\
                🤔 Oops, this doesn't seem like a MediaWiki site...

                💡 There are some working examples for you to try, though:
                """
            )
            + "\n".join(srcs)
        )
        return

    title = urlparse(redir).path.removeprefix("/")
    for prefix in filter(None, prefixes):
        title = title.removeprefix(prefix)
    title = urldecode(title)

    await msg.reply(
        textwrap.dedent(
            f"""\
            📖 (Paper fluttering...)
            Here you go!

            "{title}":
            {redir}
            """
        )
    )


async def etymology(msg: Message) -> None:
    if len(txt := msg.text.split(maxsplit=1)) != 2:
        await help(msg)
        return
    kw = txt[1]

    if kw.startswith(CMD_OPTION_PREFIX):
        if len(txt := kw.split(maxsplit=1)) != 2:
            await help(msg)
            return
        [lang, kw] = txt
        lang = lang.lstrip(CMD_OPTION_PREFIX)
    else:
        lang = langdetect.detect(kw).split("-", maxsplit=1)[0]
    lang = iso639.Lang(lang).name
    logging.info(f"/etymology: Querying `{kw}` in {lang}")

    async def query(lang: str, kw: str) -> str:
        parser = wiktionary.WiktionaryParser()
        parser.set_default_language(lang)
        # `parser.fetch()` operation is blocking, so we need to launch it in the async
        # context.
        data = await asyncio.to_thread(lambda: parser.fetch(kw))
        etys = (i["etymology"] for i in data)
        return "\n\n".join(
            f"{i+1}. {ety.strip()}" for (i, ety) in enumerate(etys) if ety
        )

    if not (etys_str := await query(lang, kw)) and lang != "English":
        # Retry once with English.
        etys_str = await query("English", kw)

    etys_str = (
        etys_str or f"😯 Oops, 404 NOT FOUND! (It seems like {lang} to me, though.)"
    )

    src = f"https://en.wiktionary.org/wiki/{urlencode(kw)}"
    await msg.reply(
        "\n\n".join(["🧐 Let me look it up...", f"{kw}:", etys_str, f"src: {src}"])
    )


if __name__ == "__main__":
    main()
