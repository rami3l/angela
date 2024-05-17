package bot

import (
	"cmp"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

// https://github.com/crazedpsyc/python-duckduckgo/blob/7c9f9d9c6ea2d08ea8ba51d92c2f591656af87bf/duckduckgo.py#L137
type duckDuckGoResp struct {
	Answer        string
	Abstract      string
	Definition    string
	Redirect      string
	RelatedTopics []struct{ Result string }
}

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

	respObj := duckDuckGoResp{}
	json.Unmarshal(resp.Body(), &respObj)
	log.WithField("resp", fmt.Sprintf("%+v", respObj)).Debug("/ddg: Got recommendation")

	fstResult := ""
	if topics := respObj.RelatedTopics; len(topics) != 0 {
		fstResult = topics[0].Result
	}
	body := cmp.Or(
		respObj.Answer, respObj.Abstract, fstResult, respObj.Definition, respObj.Redirect,
	)
	if body == "" {
		ctx.Reply("Oops, 404 NOT FOUND...")
		return nil
	}
	return ctx.Reply(fmt.Sprintf(
		"Quack! Quack!\n\n%s", body,
	), &tgb.SendOptions{ParseMode: tgb.ModeHTML})
}
