import pytest
from angela.utils import capture_redir, unescape, urldecode, urlencode


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


@pytest.mark.parametrize(
    "decoded,encoded",
    [
        (
            "春眠暁を覚えず",
            r"%E6%98%A5%E7%9C%A0%E6%9A%81%E3%82%92%E8%A6%9A%E3%81%88%E3%81%9A",
        ),
        ("/El Niño/", r"%2FEl%20Ni%C3%B1o%2F"),
    ],
)
def test_urlencode_urldecode(decoded: str, encoded: str):
    assert urlencode(decoded) == encoded
    assert decoded == urldecode(encoded)


@pytest.mark.asyncio
async def test_capture_redir():
    assert await capture_redir("https://duck.com/") == "https://duckduckgo.com/"
    assert await capture_redir("https://duckduckgo.com/") is None
