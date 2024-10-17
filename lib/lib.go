package lib

import (
	"cmp"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/rami3l/angela/lib/bot"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v4"
)

type ContextHandler = func(ctx tgb.Context) error

type Bot struct {
	Token, Listen, PublicURL string
}

func NewBotFromEnv() *Bot {
	return &Bot{
		Token:  os.Getenv("ANGELA_TELEGRAM_BOT_TOKEN"),
		Listen: os.Getenv("ANGELA_TELEGRAM_BOT_WEBHOOK_LISTEN"),
	}
}

func (b Bot) Launch() (err error) {
	t, err := tgb.NewBot(tgb.Settings{Token: b.Token, Poller: &tgb.LongPoller{Timeout: 10 * time.Second}})
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

	t.Handle("/cheat", withLog(bot.Cheat))
	t.Handle("/ddg", withLog(bot.DuckDuckGo))
	t.Handle("/decide", withLog(bot.Decide))
	t.Handle("/etymology", withLog(bot.Etymology))
	t.Handle("/hello", withLog(bot.Hello))
	t.Handle("/randomwiki", withLog(bot.RandomWiki))
	t.Handle("/rustrelease", withLog(bot.RustRelease))

	switch host := b.Listen; host {
	case "":
		log.Info("Running in polling mode...")
		t.Start()
	default:
		log.Infof("Running in webhook mode at `%s`...", host)

		// See: https://github.com/akumarujon/telebot-webhook
		mux := http.NewServeMux()

		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			_, _ = w.Write([]byte("OK"))
		})

		mux.HandleFunc(fmt.Sprintf("POST /%s", b.Token), func(w http.ResponseWriter, r *http.Request) {
			body, err := io.ReadAll(r.Body)
			defer r.Body.Close()

			if err != nil {
				log.Errorf("failed to parse update: %s", err)
				return
			}

			var update tgb.Update
			if err := json.Unmarshal(body, &update); err != nil {
				log.Errorf("failed to parse update: %s", err)
				return
			}

			t.ProcessUpdate(update)
		})

		mux.HandleFunc("GET /webhook", func(w http.ResponseWriter, r *http.Request) {
			webhook := tgb.Webhook{
				Listen: host,
				Endpoint: &tgb.WebhookEndpoint{
					PublicURL: fmt.Sprintf("%s/%s", host, b.Token),
				},
			}
			_ = t.SetWebhook(&webhook)
			_, _ = w.Write([]byte("OK, set"))
		})

		port := cmp.Or(os.Getenv("PORT"), "443")
		_ = http.ListenAndServe(":"+port, mux)
	}
	return
}
