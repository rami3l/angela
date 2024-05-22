package bot

import (
	"fmt"
	"net/url"
	"regexp"
	"strings"

	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

func Cheat(ctx tgb.Context) error {
	args := ctx.Args()
	arg := strings.Join(args, " ")

	endpoint := "https://cheat.sh/" + url.QueryEscape(arg)
	query := map[string]string{
		"style": "bw",
	}

	resp, err := resty.New().R().SetQueryParams(query).Get(endpoint)
	if err != nil {
		return err
	}

	respStr := resp.String()
	pat := regexp.MustCompile(`\<pre\>((.|\n|\r)*)\<\/pre\>`)
	matches := pat.FindStringSubmatch(respStr)
	if len(matches) < 1 {
		log.WithField("result", respStr).Info("/cheat: redirect result not found")
		return ctx.Reply("Oops, 404 NOT FOUND...")
	}
	body := matches[1]
	return ctx.Reply(fmt.Sprintf(
		"Seems like I can help!\n\n```%s```\n\nsrc: %s",
		body, endpoint,
	), &tgb.SendOptions{ParseMode: tgb.ModeMarkdown})
}
