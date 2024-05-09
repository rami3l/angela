package bot

import (
	"fmt"
	"time"

	tgb "gopkg.in/telebot.v3"
)

func RustRelease(ctx tgb.Context) error {
	type rustV1Release struct{ date time.Time }

	epoch := time.Date(2015, time.December, 10, 0, 0, 0, 0, time.UTC)
	const (
		epochRelease = 5
		dtFmt        = "Jan 02 2006"
	)

	minor := func(r rustV1Release) int {
		weeksSinceEpoch := int(r.date.Sub(epoch).Hours()) / (24 * 7)
		if weeksSinceEpoch < 0 {
			return -1
		}
		newReleases := weeksSinceEpoch / 6
		return epochRelease + newReleases
	}

	releaseDate := func(r rustV1Release) time.Time {
		newReleases := minor(r) - epochRelease
		return epoch.AddDate(0, 0, newReleases*6*7)
	}

	sprintRelease := func(r rustV1Release) string {
		return fmt.Sprintf("\tRust v1.%d\t(%s)", minor(r), releaseDate(r).Format(dtFmt))
	}

	// Based on https://forge.rust-lang.org/js/index.js.
	now := time.Now()
	stable := rustV1Release{now}
	beta := rustV1Release{now.AddDate(0, 0, 7*6)}
	nightly := rustV1Release{now.AddDate(0, 0, 7*6*2)}
	next := rustV1Release{now.AddDate(0, 0, 7*6*3)}

	return ctx.Send(fmt.Sprintf(
		"Oh, I just asked Ferris 🦀️...\n\nstable:%s\nbeta:%s\nnightly:%s\nnext:%s\n",
		sprintRelease(stable), sprintRelease(beta), sprintRelease(nightly), sprintRelease(next),
	), &tgb.SendOptions{ParseMode: tgb.ModeMarkdown})
}
