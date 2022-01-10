package lib

import (
	"fmt"
	"math/rand"

	tgb "gopkg.in/tucnak/telebot.v2"
)

func onHello(bot *tgb.Bot, msg *tgb.Message) {
	bot.Send(msg.Sender, fmt.Sprintf("%s, I'm right beside you!", msg.Sender.FirstName))
}

func onDecide(bot *tgb.Bot, msg *tgb.Message) {
	args := StripCmdHead(msg.Text)
	// TODO: Refactor this with generic RandItem[T] when Golang v1.18 comes out.
	item := args[rand.Intn(len(args))]
	bot.Send(msg.Sender, fmt.Sprintf("Emmm... I'd say %s.", item))
}
