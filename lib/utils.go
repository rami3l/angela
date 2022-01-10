package lib

import (
	"encoding/json"
	"strings"
)

func StripCmdHead(cmd string) []string {
	return strings.Fields(cmd)[1:]
}

// Shamelessly copied from https://gist.github.com/spicydog/54703add01e82e3c071482c2ce4e7c22#gistcomment-4007521.
func UnescapeUtf8(inStr string) (outStr string, err error) {
	jsonStr := `"` + strings.ReplaceAll(inStr, `"`, `\"`) + `"`
	err = json.Unmarshal([]byte(jsonStr), &outStr)
	return
}
