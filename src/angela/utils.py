import functools
import json
import ssl
import urllib.parse
from dataclasses import dataclass
from datetime import date, timedelta

import aiohttp
import certifi
from overrides import overrides

SSL_CTX = ssl.create_default_context(cafile=certifi.where())


def unescape(s: str) -> str:
    return json.loads(f'"{s}"')


urlencode = functools.partial(urllib.parse.quote, safe="")
urldecode = urllib.parse.unquote


async def capture_redir(url: str) -> str | None:
    async with aiohttp.ClientSession() as session, session.get(
        url, ssl=SSL_CTX
    ) as resp:
        return redir if (redir := str(resp.url)).lower() != url.lower() else None


@dataclass
class RustV1Release:
    curr_date: date

    EPOCH = date(2015, 12, 10)
    EPOCH_MINOR = 5
    RELEASE_PERIOD_WEEKS = 6
    RELEASE_PERIOD = timedelta(weeks=RELEASE_PERIOD_WEEKS)

    @property
    def minor(self) -> int:
        weeks_since_epoch = (self.curr_date - self.EPOCH).days // 7
        new_minors = weeks_since_epoch // self.RELEASE_PERIOD_WEEKS
        return self.EPOCH_MINOR + new_minors

    @property
    def release_date(self) -> date:
        new_minors = self.minor - self.EPOCH_MINOR
        return self.EPOCH + new_minors * self.RELEASE_PERIOD

    @overrides
    def __str__(self) -> str:
        date_str = self.release_date.strftime("%b %d %Y")
        return f"Rust v1.{self.minor}\t({date_str})"
