package lib

import (
	"time"

	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

type ContextHandler = func(ctx tgb.Context) error

func LaunchBot(token string) (err error) {
	bot, err := tgb.NewBot(tgb.Settings{
		Token:  token,
		Poller: &tgb.LongPoller{Timeout: 10 * time.Second},
	})
	if err != nil {
		log.Fatal(err)
		return err
	}

	withLog := func(handler ContextHandler) ContextHandler {
		return func(ctx tgb.Context) (err error) {
			log.WithField("msg", ctx.Text()).Info("Triggered")
			if err = handler(ctx); err != nil {
				log.Warning(err)
			}
			return
		}
	}

	bot.Handle("/hello", withLog(onHello))
	bot.Handle("/decide", withLog(onDecide))
	bot.Handle("/rustrelease", withLog(onRustRelease))
	bot.Handle("/randomwiki", withLog(onRandomWiki))
	bot.Handle("/etymology", withLog(onEtymology))

	bot.Start()
	return
}
