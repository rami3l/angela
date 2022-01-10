package lib

import (
	"encoding/json"
	"strings"
)

func StripCmdHead(cmd string) []string {
	return strings.Fields(cmd)[1:]
}

// Shamelessly copied from https://gist.github.com/spicydog/54703add01e82e3c071482c2ce4e7c22#file-unescape-decode-utf-8-string-in-go.
func UnescapeUtf8(jsonStr string) (outStr string, err error) {
	err = json.Unmarshal([]byte(`"`+jsonStr+`"`), &outStr)
	return
}
