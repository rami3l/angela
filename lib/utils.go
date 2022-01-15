package lib

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

func StripCmdHead(cmd string) []string {
	return strings.Fields(cmd)[1:]
}

// Shamelessly copied from https://gist.github.com/spicydog/54703add01e82e3c071482c2ce4e7c22#file-unescape-decode-utf-8-string-in-go.
func UnescapeUtf8(jsonStr string) (outStr string, err error) {
	err = json.Unmarshal([]byte(`"`+jsonStr+`"`), &outStr)
	return
}

type RustV1Release struct{ date time.Time }

var epochTime time.Time = time.Date(2015, time.December, 10, 0, 0, 0, 0, time.UTC)

const epochRelease = 5

func (r RustV1Release) Minor() int {
	weeksSinceEpoch := int(r.date.Sub(epochTime).Hours()) / (24 * 7)
	if weeksSinceEpoch < 0 {
		return -1
	}
	newReleases := weeksSinceEpoch / 6
	return epochRelease + newReleases
}

func (r RustV1Release) ReleaseDate() time.Time {
	newReleases := r.Minor() - epochRelease
	return epochTime.AddDate(0, 0, newReleases*6*7)
}

func (r RustV1Release) String() string {
	return fmt.Sprintf("Rust v1.%d", r.Minor())
}

func CurrentRustV1Release() RustV1Release {
	return RustV1Release{time.Now()}
}

func (r RustV1Release) Beta() (res RustV1Release) {
	res.date = r.date.AddDate(0, 0, 7*6)
	return
}

func (r RustV1Release) Nightly() (res RustV1Release) {
	res.date = r.date.AddDate(0, 0, 7*6*2)
	return
}

func (r RustV1Release) Next() (res RustV1Release) {
	res.date = r.date.AddDate(0, 0, 7*6*3)
	return
}
