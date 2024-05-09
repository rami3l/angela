package bot

import (
	"math/rand/v2"

	tgb "gopkg.in/telebot.v3"
)

func Decide(ctx tgb.Context) error {
	args := ctx.Args()
	item := args[rand.IntN(len(args))]
	return ctx.Reply(item)
}
