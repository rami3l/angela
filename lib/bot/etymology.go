package bot

import (
	"bufio"
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
	pat := regexp.MustCompile(`\"extract\":\"(.*)\"`)
	matches := pat.FindStringSubmatch(respStr)
	if len(matches) < 1 {
		log.WithField("result", respStr).Info("/etymology: Wiktionary extract not found")
		ctx.Send("Oops, looks like there isn't such a word in Wiktionary...")
		return nil
	}

	rawExtract := matches[1]
	log.WithField("rawExtract", rawExtract).Debug("/etymology: Got raw extract")
	extract, err := utils.UnescapeUtf8(rawExtract)
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
	return ctx.Send(reply)
}
