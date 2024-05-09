package bot

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

func DuckDuckGo(ctx tgb.Context) error {
	args := ctx.Args()
	arg := strings.Join(args, " ")

	endpoint := "https://api.duckduckgo.com/"
	query := map[string]string{
		"q": arg,
		"o": "json",
		// Safe search: -1 for OFF, 1 for ON
		"kp":          "-1",
		"no_redirect": "1",
		"no_html":     "0",
		// Include disambiguation
		"d": "0",
	}

	resp, err := resty.New().R().SetQueryParams(query).Get(endpoint)
	if err != nil {
		return err
	}

	respStr := resp.String()
	pat := regexp.MustCompile(`\"Redirect\":\"(.*?)\"`)
	matches := pat.FindStringSubmatch(respStr)
	if len(matches) < 1 {
		log.WithField("result", respStr).Info("/ddg: redirect result not found")
		ctx.Reply("Oops, 404 NOT FOUND...")
		return nil
	}
	body := matches[1]
	return ctx.Reply(fmt.Sprintf("Quack! Quack!\n\n%s", body))
}
