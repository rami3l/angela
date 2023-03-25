import argparse
import asyncio
import logging
import os
import random
import textwrap
from datetime import date, datetime
from typing import Awaitable, Callable
from urllib.parse import urlparse

import cheat_sh
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
    coloredlogs.install()  # type: ignore

    logging.warning("Angela is waking up...")

    dp = Dispatcher(Bot(token=opts.token))

    cmds = [
        "cheat",
        "ddg",
        "decide",
        "etymology",
        "hello",
        "help",
        "random_wiki",
        "rust_release",
    ]
    for cmd in cmds:
        handler = log_err(globals()[cmd])  # * Dynamic magic!
        cmd_r = cmd.replace("_", "")
        dp.message_handler(commands=cmd_r)(handler)
        dp.edited_message_handler(commands=cmd_r)(handler)

    executor.start_polling(dp)


def log_err(
    f: Callable[[Message], Awaitable[None]]
) -> Callable[[Message], Awaitable[None]]:
    async def f1(msg: Message) -> None:
        try:
            await f(msg)
        except Exception as e:
            logging.error(f"{f.__name__}: {e}")
            await msg.reply(f"🤯 Oops, an error occurred!\n\n{e}")

    return f1


async def help(msg: Message, usages: list[str] | None = None) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    reply = "\n".join(
        [f"🤔 Dear {title}, what's on your mind?"]
        + (["\n💡 Maybe you could try one of the following:"] + usages if usages else [])
    )
    await msg.reply(reply)


async def hello(msg: Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"👋 {title}, I'm right beside you!")


async def ddg(msg: Message) -> None:
    if not (kw := msg.get_args()):
        await help(msg, usages=["/ddg GitHub", "/ddg !wiktionary rust"])
        return
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
    if not ((args := msg.get_args()) and (options := args.split())):
        await help(msg, usages=["/decide head tail"])
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
        "www.explainxkcd.com",
        "wiki.archlinux.org",
        "wiki.haskell.org",
    ]

    category: str | None = None
    match (args := msg.get_args()) and args.split():
        case [src, category, *_]:
            category = category.lstrip(CMD_OPTION_PREFIX)
        case [src]:
            ...
        case _:
            src = random.choice(srcs)

    prefixes = ["wiki/", "wiki/index.php/", "title/", ""]
    suffix = (
        f"Special:RandomInCategory/{urlencode(category)}"
        if category
        else "Special:Random"
    )

    async def handle_prefix(prefix: str):
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


@log_err
async def etymology(msg: Message) -> None:
    if not (args := msg.get_args()):
        await help(
            msg,
            usages=[
                "/etymology 春眠暁を覚えず",
                "/etymology %de Kaiser",
                "/etymology %Latin nodus",
            ],
        )
        return

    detected_lang: str | None = None
    match args.lstrip(CMD_OPTION_PREFIX).split(maxsplit=1):
        case [lang, kw] if args.startswith(CMD_OPTION_PREFIX):
            ...
        case _:
            kw = args
            lang = detected_lang = langdetect.detect(kw).split("-", maxsplit=1)[0]

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
        etys_str = await query(lang := "English", kw)

    if etys_str:
        kw_str = f"{kw} [{iso639.Lang(lang).pt1}]:"
    else:
        etys_str = "😯 Oops, 404 NOT FOUND!"
        if detected_lang:
            etys_str += (
                f"\n(Looks like {iso639.Lang(detected_lang).name} to me, though.)"
            )
        kw_str = f"{kw}:"

    src = f"https://en.wiktionary.org/wiki/{urlencode(kw)}"
    await msg.reply(
        "\n\n".join(["🧐 Let me look it up...", kw_str, etys_str, f"src: {src}"])
    )


@log_err
async def cheat(msg: Message) -> None:
    if not (kws := msg.get_args()):
        await help(
            msg,
            usages=[
                "/cheat clojure reverse list",
                "/cheat golang read string line by line",
            ],
        )
        return

    ans = await asyncio.to_thread(lambda: cheat_sh.requests_cheat_sh(kws))
    src = ("http://cheat.sh/" + urlencode(kws, safe="/+")).rstrip("/")
    await msg.reply("\n\n".join(["💡 Seems like I can help!", ans, f"src: {src}"]))


if __name__ == "__main__":
    main()
