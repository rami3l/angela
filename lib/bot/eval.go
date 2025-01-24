package bot

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v4"
)

func Eval(ctx tgb.Context) error {
	_, src, _ := strings.Cut(ctx.Message().Text, " ")
	if strings.TrimSpace(src) == "" {
		return ctx.Reply("Usage: /eval <rust_code>")
	}

	wrappedSrc := wrapMain(src)
	log.Debugf("/eval: evaluating the following snippet:\n```rs\n%s```", wrappedSrc)

	endpoint := "https://play.rust-lang.org/execute"
	body := map[string]any{
		"crateType": "bin",
		"channel":   "nightly",
		"edition":   "2024",
		"mode":      "debug",
		"tests":     false,
		"backtrace": true,
		"code":      wrappedSrc,
	}

	resp, err := resty.New().R().SetBody(body).Post(endpoint)
	if err != nil {
		return err
	}

	var evalRes rustPlaygroundResp
	if err := json.Unmarshal(resp.Body(), &evalRes); err != nil {
		return err
	}

	leader := ":)"
	if !evalRes.Success {
		leader = ":<"
		if evalRes.Error != "" {
			return ctx.Reply(fmt.Sprintf("%s %s", leader, evalRes.Error))
		}
	}
	return ctx.Reply(fmt.Sprintf(
		"%s %s\n\nSTDOUT\n%s\nSTDERR\n%s",
		leader, evalRes.ExitDetail, evalRes.Stdout, evalRes.Stderr,
	))
}

type rustPlaygroundResp struct {
	// The error message emitted by the playground server, if any.
	Error          string
	Success        bool
	ExitDetail     string
	Stdout, Stderr string
}

func wrapMain(src string) string {
	var blk string
	switch {
	case
		strings.Contains(src, "print!("),
		strings.Contains(src, "println!("):
		blk = "{\n%s\n};"
	default:
		blk = "println!(\"{:?}\", {\n%s\n});"
	}
	return fmt.Sprintf(
		`#[allow(warnings)] fn main() -> Result<(), Box<dyn std::error::Error>> {
%s
	Ok(())
}`,
		fmt.Sprintf(blk, src),
	)
}
