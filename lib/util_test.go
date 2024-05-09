package lib

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCaptureRedirect(t *testing.T) {
	url := "https://duck.com"
	got, err := CaptureRedirect(url)
	assert.Nil(t, err)
	assert.Equal(t, "https://duckduckgo.com/", got)
}

func TestUnescapeUtf8(t *testing.T) {
	escaped := "\\n== English ==\\n\\n\\n=== Etymology 1 ===\\nAttested since the 16th century; borrowed from Scots wow.\\n\\n\\n==== Pronunciation ====\\nenPR: wou, IPA(key): /wa\\u028a\\u032f/\\n\\nRhymes: -a\\u028a\\n\\n\\n==== Interjection ====\\nwow\\n\\nAn indication of excitement, surprise, astonishment, or pleasure.\\n1513, Gavin Douglas, Virgil \\u00c6neid (translation) vi. Prol. 19:\\nOut on thir wanderand spiritis, wow! thow cryis.\\nAn expression of amazement, awe, or admiration.\\n\\nUsed sarcastically to express disapproval of something.\\n\\n\\n===== Synonyms =====\\nSee also Thesaurus:wow\\n\\n\\n===== Derived terms =====\\n\\n\\n===== Translations =====\\n\\n\\n==== Verb ====\\nwow (third-person singular simple present wows, present participle wowing, simple past and past participle wowed)\\n\\n(transitive, informal) To amaze or awe.\\n\\n\\n===== Translations =====\\n\\n\\n==== Noun ====\\nwow (plural wows)\\n\\n(informal) Anything exceptionally surprising, unbelievable, outstanding, etc.\\n\\n1991, Stephen Fry, The Liar, p. 27:\\n\\u2018Jesus suffering fuck,\\u2019 said Adrian. \\u2018It's not half a thought.\\u2019\\u00b6 \\u2018Face it, it's a wow.\\u2019\\n\\n\\n===== Derived terms =====\\nwowless\\n\\n\\n=== Etymology 2 ===\\nImitative.\\n\\n\\n==== Noun ====\\nwow (countable and uncountable, plural wows)\\n\\n(audio) A relatively slow form of flutter (pitch variation) which can affect both gramophone records and tape recorders.\\n1970, Larry G. Goodwin, \\u200eThomas Koehring, Closed-circuit Television Production Techniques (page 80)\\nSound films have to be loaded so that the sound is 5 seconds before the sound drum so a wow does not result when the film is punched up on the air.\\n\\n\\n=== Anagrams ===\\noww\\n\\n\\n== Atikamekw ==\\n\\n\\n=== Noun ===\\nwow\\n\\negg\\n\\n\\n== Middle English ==\\n\\n\\n=== Noun ===\\nwow\\n\\nAlternative form of wowe\\n\\n\\n== Polish ==\\n\\n\\n=== Etymology ===\\nFrom English wow.\\n\\n\\n=== Pronunciation ===\\nIPA(key): /waw/\\n\\n\\n=== Interjection ===\\nwow\\n\\n(colloquial, slang, informal) wow\\n\\n\\n=== Further reading ===\\nwow in Wielki s\\u0142ownik j\\u0119zyka polskiego, Instytut J\\u0119zyka Polskiego PAN\\nwow in Polish dictionaries at PWN\\n\\n\\n== Spanish ==\\n\\n\\n=== Etymology ===\\nUnadapted borrowing from English wow.\\n\\n\\n=== Pronunciation ===\\nIPA(key): /\\u02c8wau/, [\\u02c8wau\\u032f]\\n\\n\\n=== Interjection ===\\nwow\\n\\nwow (an indication of excitement or surprise)\\n\\n\\n==== Usage notes ====\\nAccording to Royal Spanish Academy (RAE) prescriptions, unadapted foreign words should be written in italics in a text printed in roman type, and vice versa, and in quotation marks in a manuscript text or when italics are not available. In practice, this RAE prescription is not always followed."
	unescaped := `
== English ==


=== Etymology 1 ===
Attested since the 16th century; borrowed from Scots wow.


==== Pronunciation ====
enPR: wou, IPA(key): /waʊ̯/

Rhymes: -aʊ


==== Interjection ====
wow

An indication of excitement, surprise, astonishment, or pleasure.
1513, Gavin Douglas, Virgil Æneid (translation) vi. Prol. 19:
Out on thir wanderand spiritis, wow! thow cryis.
An expression of amazement, awe, or admiration.

Used sarcastically to express disapproval of something.


===== Synonyms =====
See also Thesaurus:wow


===== Derived terms =====


===== Translations =====


==== Verb ====
wow (third-person singular simple present wows, present participle wowing, simple past and past participle wowed)

(transitive, informal) To amaze or awe.


===== Translations =====


==== Noun ====
wow (plural wows)

(informal) Anything exceptionally surprising, unbelievable, outstanding, etc.

1991, Stephen Fry, The Liar, p. 27:
‘Jesus suffering fuck,’ said Adrian. ‘It's not half a thought.’¶ ‘Face it, it's a wow.’


===== Derived terms =====
wowless


=== Etymology 2 ===
Imitative.


==== Noun ====
wow (countable and uncountable, plural wows)

(audio) A relatively slow form of flutter (pitch variation) which can affect both gramophone records and tape recorders.
1970, Larry G. Goodwin, ` + "\u200e" + `Thomas Koehring, Closed-circuit Television Production Techniques (page 80)
Sound films have to be loaded so that the sound is 5 seconds before the sound drum so a wow does not result when the film is punched up on the air.


=== Anagrams ===
oww


== Atikamekw ==


=== Noun ===
wow

egg


== Middle English ==


=== Noun ===
wow

Alternative form of wowe


== Polish ==


=== Etymology ===
From English wow.


=== Pronunciation ===
IPA(key): /waw/


=== Interjection ===
wow

(colloquial, slang, informal) wow


=== Further reading ===
wow in Wielki słownik języka polskiego, Instytut Języka Polskiego PAN
wow in Polish dictionaries at PWN


== Spanish ==


=== Etymology ===
Unadapted borrowing from English wow.


=== Pronunciation ===
IPA(key): /ˈwau/, [ˈwau̯]


=== Interjection ===
wow

wow (an indication of excitement or surprise)


==== Usage notes ====
According to Royal Spanish Academy (RAE) prescriptions, unadapted foreign words should be written in italics in a text printed in roman type, and vice versa, and in quotation marks in a manuscript text or when italics are not available. In practice, this RAE prescription is not always followed.`
	got, err := UnescapeUtf8(escaped)
	assert.Equal(t, nil, err)
	assert.Equal(t, unescaped, got)
}
