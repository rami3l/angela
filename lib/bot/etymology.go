package bot

import (
	"fmt"
	"net/url"
	"regexp"
	"strings"

	"github.com/go-resty/resty/v2"
	"github.com/rami3l/angela/lib/utils"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v4"
)

func Etymology(ctx tgb.Context) error {
	_, arg, _ := strings.Cut(ctx.Message().Text, " ")
	if strings.TrimSpace(arg) == "" {
		return ctx.Reply("Usage: /etymology <term>")
	}

	endpoint := "https://en.wiktionary.org/w/api.php"
	query := map[string]string{
		"action":      "query",
		"format":      "json",
		"titles":      arg,
		"prop":        "extracts",
		"explaintext": "",
	}

	resp, err := resty.New().R().SetQueryParams(query).Get(endpoint)
	if err != nil {
		return err
	}

	respStr := resp.String()
	pat := regexp.MustCompile(`\"extract\":\"(.*?[^\\])\"`)
	matches := pat.FindStringSubmatch(respStr)
	if len(matches) < 1 {
		log.WithField("result", respStr).Info("/etymology: Wiktionary extract not found")
		return ctx.Reply("Oops, looks like there isn't such a word in Wiktionary...")
	}

	rawExtract := matches[1]
	body := ""
	// NOTE: The body can be too long to fit into Telegram's message size limit of 4096.
	// As such, a potentially truncated version of the body is sent.
	maxLen := 2000
	for i, entry := range extractEtymology(rawExtract) {
		item := fmt.Sprintf("%d. %s", i+1, entry) + "\n\n"
		if len(body)+len(item) >= maxLen {
			body += "...\n\n"
			break
		}
		body += item
	}

	var reply string
	src := "https://en.wiktionary.org/wiki/" + url.PathEscape(arg)
	if strings.TrimSpace(body) == "" {
		log.Info("/etymology: no etymology entries found")
		reply = fmt.Sprintf("Let me look it up...\n\nOops, it seems that I can't find the etymology in %s...", src)
	} else {
		log.WithField("body", body).Debug("/etymology: got body")
		reply = fmt.Sprintf("Let me look it up...\n\n%s:\n\n%ssrc: %s", arg, body, src)
	}
	return ctx.Reply(reply)
}

func extractEtymology(rawExtract string) (entries []string) {
	log.WithField("rawExtract", rawExtract).Debug("/etymology: got raw extract")
	extract, err := utils.UnescapeUtf8(rawExtract)
	if err != nil {
		log.Warnf("/etymology: error unescaping extract: %s", err)
	}
	log.WithField("extract", extract).Debug("/etymology: got extract")

	lns := strings.Split(extract, "\n")
	entryLns := []string{}
	for i := 0; i < len(lns); i++ {
		for ; i < len(lns) && !strings.Contains(lns[i], "= Etymology"); i++ {
		}
		i++
		for ; i < len(lns) && !strings.HasPrefix(lns[i], "="); i++ {
			if strings.TrimSpace(lns[i]) != "" {
				entryLns = append(entryLns, lns[i])
			}
		}
		if len(entryLns) != 0 {
			entries = append(entries, strings.Join(entryLns, "\n"))
			entryLns = entryLns[:0]
		}
	}
	return
}
