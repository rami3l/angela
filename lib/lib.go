package lib

import (
	"time"

	"github.com/rami3l/angela/lib/bot"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

type ContextHandler = func(ctx tgb.Context) error

func LaunchBot(token string) (err error) {
	b, err := tgb.NewBot(tgb.Settings{
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

	b.Handle("/cheat", withLog(bot.Cheat))
	b.Handle("/ddg", withLog(bot.DuckDuckGo))
	b.Handle("/decide", withLog(bot.Decide))
	b.Handle("/etymology", withLog(bot.Etymology))
	b.Handle("/hello", withLog(bot.Hello))
	b.Handle("/randomwiki", withLog(bot.RandomWiki))
	b.Handle("/rustrelease", withLog(bot.RustRelease))

	b.Start()
	return
}
