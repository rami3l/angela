package lib

import (
	"encoding/json"
	"net/http"
)

// Shamelessly copied from https://gist.github.com/spicydog/54703add01e82e3c071482c2ce4e7c22#file-unescape-decode-utf-8-string-in-go.
func UnescapeUtf8(jsonStr string) (outStr string, err error) {
	err = json.Unmarshal([]byte(`"`+jsonStr+`"`), &outStr)
	return
}

func CaptureRedirect(url string) (redirected string, err error) {
	res, err := http.Get(url)
	if err != nil {
		return
	}
	redirected = res.Request.URL.String()
	return
}
