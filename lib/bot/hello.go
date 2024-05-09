package bot

import (
	"cmp"
	"fmt"

	tgb "gopkg.in/telebot.v3"
)

func Hello(ctx tgb.Context) error {
	return ctx.Reply(fmt.Sprintf(
		"%s, I'm right beside you!",
		cmp.Or(ctx.Sender().FirstName, "Hi"),
	))
}
