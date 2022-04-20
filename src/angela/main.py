import argparse
import logging
import os

from aiogram import Bot, Dispatcher, executor, types
from dotenv import load_dotenv


def greeting() -> str:
    return "Hello from Angela!"


def main() -> None:
    load_dotenv()

    parser = argparse.ArgumentParser(description="test")
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

    logging.info("Angela is waking up...")

    bot = Bot(token=opts.token)
    dp = Dispatcher(bot)

    dp.message_handler(commands="hello")(hello)

    executor.start_polling(dp)


async def hello(msg: types.Message) -> None:
    title = src.first_name if (src := msg.from_user) is not None else "Hi"
    await msg.reply(f"{title}, I'm right beside you!")


if __name__ == "__main__":
    main()
