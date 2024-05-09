package bot

import (
	"fmt"

	"github.com/rami3l/angela/lib/utils"
	log "github.com/sirupsen/logrus"
	tgb "gopkg.in/telebot.v3"
)

func RandomWiki(ctx tgb.Context) error {
	url, err := utils.CaptureRedirect("https://en.wikipedia.org/wiki/Special:Random")
	if err != nil {
		return err
	}
	log.WithField("pageUrl", url).Info("/randomwiki: Got random page")
	return ctx.Send(fmt.Sprintf("(Paper fluttering...)\n\nHere you go!\n%s", url))
}
