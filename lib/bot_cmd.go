package lib

import (
	"bufio"
	"fmt"
	"math/rand"
	"net/url"
	"regexp"
	"strings"

	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/tucnak/telebot.v2"
)

func onHello(bot *tgb.Bot, msg *tgb.Message) {
	bot.Send(msg.Chat, fmt.Sprintf("%s, I'm right beside you!", msg.Sender.FirstName))
}

func onDecide(bot *tgb.Bot, msg *tgb.Message) {
	args := StripCmdHead(msg.Text)
	// TODO: Refactor this with generic RandItem[T] when Golang v1.18 comes out.
	item := args[rand.Intn(len(args))]
	bot.Send(msg.Chat, fmt.Sprintf("Emmm... I'd say %s.", item))
}

func onRustRelease(bot *tgb.Bot, msg *tgb.Message) {
	// Based on https://forge.rust-lang.org/js/index.js.
	curr := CurrentRustV1Release()
	stable := curr
	beta := curr.Beta()
	nightly := curr.Nightly()
	next := curr.Next()
	const dtFmt = "02 Jan 2006"

	bot.Send(msg.Chat, fmt.Sprintf("Oh, I just asked Ferris 🦀️:\n\n```\n%s\n%s\n%s\n%s\n```",
		fmt.Sprintf("stable:\t%s\t(%s)", stable, stable.ReleaseDate().Format(dtFmt)),
		fmt.Sprintf("beta:\t%s\t(%s)", beta, beta.ReleaseDate().Format(dtFmt)),
		fmt.Sprintf("nightly:\t%s\t(%s)", nightly, nightly.ReleaseDate().Format(dtFmt)),
		fmt.Sprintf("next:\t%s\t(%s)", next, next.ReleaseDate().Format(dtFmt)),
	), &tgb.SendOptions{ParseMode: tgb.ModeMarkdown})
}

func onEtymology(bot *tgb.Bot, msg *tgb.Message) {
	args := StripCmdHead(msg.Text)
	arg := strings.Join(args, " ")

	endpoint := "https://en.wiktionary.org/w/api.php"
	query := map[string]string{
		"action":      "query",
		"format":      "json",
		"titles":      arg,
		"prop":        "extracts",
		"explaintext": "",
	}

	client := resty.New()
	res, err := client.R().
		SetQueryParams(query).
		Get(endpoint)
	if err != nil {
		log.Warning(err)
		return
	}

	resStr := res.String()
	pat := regexp.MustCompile(`\"extract\":\"(.*)\"`)
	matches := pat.FindStringSubmatch(resStr)
	if len(matches) < 1 {
		log.WithField("result", resStr).Info("/etymology: Wiktionary extract not found")
		bot.Send(msg.Chat, "Emmm... Is there really such a word?")
	}

	rawExtract := matches[1]
	log.WithField("rawExtract", rawExtract).Debug("/etymology: Got raw extract")
	extract, err := UnescapeUtf8(rawExtract)
	if err != nil {
		log.Warnf("/etymology: Error unescaping extract: %s", err)
	}
	log.WithField("extract", extract).Debug("/etymology: Got extract")

	fstEntryLns := []string{}

	// Read `extract` line by line and extract the first etymology entry.
	scanner := bufio.NewScanner(strings.NewReader(extract))
	// Skip while the current line doesn't contain the substring.
	for scanner.Scan() && !strings.Contains(scanner.Text(), "= Etymology") {
	}
	// Take while the current line doesn't start with the prefix.
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "=") {
			break
		}
		if strings.TrimSpace(line) != "" {
			fstEntryLns = append(fstEntryLns, line)
		}
	}

	fstEntry := strings.Join(fstEntryLns, "\n")
	src := fmt.Sprintf("https://en.wiktionary.org/wiki/%s", url.QueryEscape(arg))

	var reply string
	if strings.TrimSpace(fstEntry) == "" {
		log.Info("/etymology: No etymology entries found")
		reply = fmt.Sprintf("Let me look it up...\n\nOops, it seems that I can't find the etymology in %s...", src)
	} else {
		log.WithField("fstEntry", fstEntry).Info("/etymology: Got first entry")
		reply = fmt.Sprintf("Let me look it up...\n\n%s:\n\n%s\n\nsrc: %s", arg, fstEntry, src)
	}
	bot.Send(msg.Chat, reply)
}
