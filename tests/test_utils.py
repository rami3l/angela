import pytest
from angela.utils import capture_redir, unescape, urlencode


def test_unescape():
    original = "== English ==\\n\\n\\n=== Etymology 1 ===\\nAttested since the 16th century; borrowed from Scots wow.\\n\\n\\n==== Pronunciation ====\\nenPR: wou, IPA(key): /wa\\u028a\\u032f/\\n\\nRhymes: -a\\u028a"
    expected = """\
== English ==


=== Etymology 1 ===
Attested since the 16th century; borrowed from Scots wow.


==== Pronunciation ====
enPR: wou, IPA(key): /waʊ̯/

Rhymes: -aʊ\
"""
    assert unescape(original) == expected


def test_urlencode():
    original = "春眠暁を覚えず"
    expected = r"%E6%98%A5%E7%9C%A0%E6%9A%81%E3%82%92%E8%A6%9A%E3%81%88%E3%81%9A"
    assert urlencode(original) == expected


@pytest.mark.asyncio
async def test_capture_redir():
    url = "https://duck.com/"
    got = await capture_redir(url)
    assert got == "https://duckduckgo.com/"
