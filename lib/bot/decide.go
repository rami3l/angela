package bot

import (
	"fmt"
	"math/rand/v2"

	tgb "gopkg.in/telebot.v3"
)

func Decide(ctx tgb.Context) error {
	args := ctx.Args()
	item := args[rand.IntN(len(args))]
	return ctx.Send(fmt.Sprintf("Emmm... I'd say %s.", item))
}
