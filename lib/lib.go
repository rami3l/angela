package lib

import (
	"time"

	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/tucnak/telebot.v2"
)

type MsgHandler = func(bot *tgb.Bot, msg *tgb.Message)

func LaunchBot(token string) (err error) {
	bot, err := tgb.NewBot(tgb.Settings{
		Token:  token,
		Poller: &tgb.LongPoller{Timeout: 1 * time.Second},
	})

	if err != nil {
		log.Fatal(err)
		return err
	}

	handle := func(handler MsgHandler) func(*tgb.Message) {
		return func(msg *tgb.Message) {
			log.WithField("msg", msg.Text).Info("Triggered")
			handler(bot, msg)
		}
	}

	bot.Handle("/hello", handle(onHello))
	bot.Handle("/decide", handle(onDecide))

	bot.Start()
	return
}
