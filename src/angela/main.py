import argparse
import logging
import os
import random

import coloredlogs
from aiogram import Bot, Dispatcher, executor, types
from dotenv import load_dotenv


def greeting() -> str:
    return "Hello from Angela!"


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

    executor.start_polling(dp)


async def hello(msg: types.Message) -> None:
    title = (src := msg.from_user) and src.first_name or "Hi"
    await msg.reply(f"👋 {title}, I'm right beside you!")


async def decide(msg: types.Message) -> None:
    formats = ["🤔 Emmm... I'd say {}.", "💡 What about {}?"]
    options = msg.text.split()[1:]
    if not options:
        title = (src := msg.from_user) and src.first_name or "Hi"
        await msg.reply(f"🤔 {title}, what's on your mind?")
        return
    await msg.reply(random.choice(formats).format(random.choice(options)))


if __name__ == "__main__":
    main()
