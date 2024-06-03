package bot

import (
	"fmt"
	"time"

	tgb "gopkg.in/telebot.v3"
)

const (
	epochRelease = 5
	dtFmt        = "Jan 02 2006"
)

var epoch = time.Date(2015, time.December, 10, 0, 0, 0, 0, time.UTC)

type rustV1Release struct{ date time.Time }

func (r rustV1Release) minor() int {
	weeksSinceEpoch := int(r.date.Sub(epoch).Hours()) / (24 * 7)
	if weeksSinceEpoch < 0 {
		return -1
	}
	newReleases := weeksSinceEpoch / 6
	return epochRelease + newReleases
}

func (r rustV1Release) releaseDate() time.Time {
	newReleases := r.minor() - epochRelease
	return epoch.AddDate(0, 0, newReleases*6*7)
}

func (r rustV1Release) String() string {
	return fmt.Sprintf("Rust v1.%d\t(%s)", r.minor(), r.releaseDate().Format(dtFmt))
}

func RustRelease(ctx tgb.Context) error {
	// Based on https://forge.rust-lang.org/js/index.js.
	now := time.Now()

	stable := rustV1Release{now}
	beta := rustV1Release{now.AddDate(0, 0, 7*6)}
	nightly := rustV1Release{now.AddDate(0, 0, 7*6*2)}
	next := rustV1Release{now.AddDate(0, 0, 7*6*3)}

	return ctx.Reply(fmt.Sprintf(
		"Oh, I just asked Ferris 🦀️...\n```\nstable:\t%v\nbeta:\t%v\nnightly:\t%v\nnext:\t%v```\n",
		stable, beta, nightly, next,
	), &tgb.SendOptions{ParseMode: tgb.ModeMarkdown})
}
