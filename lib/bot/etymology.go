package bot

import (
	"fmt"
	"net/url"
	"regexp"
	"strings"

	"github.com/go-resty/resty/v2"
	"github.com/rami3l/angela/lib/utils"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

func Etymology(ctx tgb.Context) error {
	args := ctx.Args()
	arg := strings.Join(args, " ")

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
	pat := regexp.MustCompile(`\"extract\":\"(.*?)\"`)
	matches := pat.FindStringSubmatch(respStr)
	if len(matches) < 1 {
		log.WithField("result", respStr).Info("/etymology: Wiktionary extract not found")
		ctx.Reply("Oops, looks like there isn't such a word in Wiktionary...")
		return nil
	}

	rawExtract := matches[1]
	body := ""
	for i, entry := range extractEtymology(rawExtract) {
		body += fmt.Sprintf("%d. %s", i+1, entry) + "\n\n"
	}

	var reply string
	src := "https://en.wiktionary.org/wiki/" + url.QueryEscape(arg)
	if strings.TrimSpace(body) == "" {
		log.Info("/etymology: No etymology entries found")
		reply = fmt.Sprintf("Let me look it up...\n\nOops, it seems that I can't find the etymology in %s...", src)
	} else {
		log.WithField("body", body).Debug("/etymology: Got body")
		reply = fmt.Sprintf("Let me look it up...\n\n%s:\n\n%ssrc: %s", arg, body, src)
	}
	return ctx.Reply(reply)
}

func extractEtymology(rawExtract string) (entries []string) {
	log.WithField("rawExtract", rawExtract).Debug("/etymology: Got raw extract")
	extract, err := utils.UnescapeUtf8(rawExtract)
	if err != nil {
		log.Warnf("/etymology: Error unescaping extract: %s", err)
	}
	log.WithField("extract", extract).Debug("/etymology: Got extract")

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
