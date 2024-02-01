import argparse
import asyncio
import logging
import os
import random
import textwrap
from datetime import date, datetime
from urllib.parse import urlparse

import cheat_sh
import coloredlogs
import duckduckgo
import iso639
import langdetect
import wiktionaryparser as wiktionary
from aiogram import Bot, Dispatcher
from aiogram.filters.command import Command, CommandObject
from aiogram.types import Message
from aiohttp import ClientConnectorError
from dotenv import load_dotenv

from angela.utils import RustV1Release, capture_redir, urldecode, urlencode

CMD_OPTION_PREFIX = "%"

dp = Dispatcher()


async def main() -> None:
    load_dotenv()
    opts = clap().parse_args()

    logging_level: int
    match opts.verbosity:
        case None:
            logging_level = logging.WARN
        case 1:
            logging_level = logging.INFO
        case _:
            logging_level = logging.DEBUG

    logging.basicConfig()
    logging.getLogger().setLevel(logging_level)
    if logging_level >= logging.INFO:
        logging.getLogger("aiogram.event").setLevel(logging.WARN)

    coloredlogs.install()  # type: ignore

    logging.warning("Angela is waking up...")
    logging.warning(f"Current logging level: {logging_level}")

    bot = Bot(token=opts.token)
    await dp.start_polling(bot)


def clap() -> argparse.ArgumentParser:
    res = argparse.ArgumentParser()
    res.add_argument(
        "--token",
        default=os.environ.get("ANGELA_TELEGRAM_BOT_TOKEN"),
        help="the Telegram bot token to be used",
    )
    res.add_argument("-v", "--verbosity", action="count", help="the logging verbosity")
    return res


@dp.message(Command("help"))
async def help(msg: Message, usages: list[str] | None = None) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    reply = "\n".join(
        [f"🤔 Dear {title}, what's on your mind?"]
        + (
            ["\n💡 Maybe you could try one of the following:"] + usages
            if usages
            else []
        )
    )
    await msg.reply(reply)


@dp.message(Command("hello"))
async def hello(msg: Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"👋 {title}, I'm right beside you!")


@dp.message(Command("ddg"))
async def ddg(msg: Message, command: CommandObject) -> None:
    if not (kw := command.args):
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


@dp.message(Command("decide"))
async def decide(msg: Message, command: CommandObject) -> None:
    if not ((args := command.args) and (options := args.split())):
        await help(msg, usages=["/decide head tail"])
        return
    formats = ["🤔 Emmm... I'd say {}.", "💡 What about {}?"]
    await msg.reply(random.choice(formats).format(random.choice(options)))


@dp.message(Command("rustrelease"))
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


@dp.message(Command("randomwiki"))
async def random_wiki(msg: Message, command: CommandObject) -> None:
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
    match (args := command.args) and args.split():
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


@dp.message(Command("etymology"))
async def etymology(msg: Message, command: CommandObject) -> None:
    async def _help():
        await help(
            msg,
            usages=[
                "/etymology earthapple",
                "/etymology %auto 春眠暁を覚えず",
                "/etymology %de Kaiser",
                "/etymology %Latin nodus",
            ],
        )

    if not (args := command.args):
        await _help()
        return

    lang: str | None = None
    if args.startswith(CMD_OPTION_PREFIX):
        match args.lstrip(CMD_OPTION_PREFIX).split(maxsplit=1):
            case [lang, kw]:
                # ["de", "Kaiser"] / ["auto", "Kaiser"]
                if lang == "auto":
                    lang = langdetect.detect(kw).split("-", maxsplit=1)[0]
            case _:
                # ["de"] / ["unknown"]
                await _help()
                return
    else:
        kw = args

    lang = iso639.Lang(lang).name if lang else None
    logging.info(f"/etymology: Querying `{kw}` in {lang or '(default language)'}")

    async def query(kw: str, lang: str | None = None) -> str:
        parser = wiktionary.WiktionaryParser()
        if lang:
            parser.set_default_language(lang)
        # `parser.fetch()` operation is blocking, so we need to launch it in the async
        # context.
        data = await asyncio.to_thread(lambda: parser.fetch(kw))
        etys = (i["etymology"] for i in data)
        return "\n\n".join(
            f"{i+1}. {ety.strip()}" for (i, ety) in enumerate(etys) if ety
        )

    if etys_str := await query(kw, lang):
        kw_str = f"{kw} [{iso639.Lang(lang).pt1}]:" if lang else f"{kw}:"
    else:
        etys_str = "😯 Oops, 404 NOT FOUND!"
        if lang:
            etys_str += f"\n(Looks like {iso639.Lang(lang).name} to me, though.)"
        kw_str = f"{kw}:"

    src = f"https://en.wiktionary.org/wiki/{urlencode(kw)}"
    await msg.reply(
        "\n\n".join(["🧐 Let me look it up...", kw_str, etys_str, f"src: {src}"])
    )


@dp.message(Command("cheat"))
async def cheat(msg: Message, command: CommandObject) -> None:
    if not (kws := command.args):
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
    asyncio.run(main())
