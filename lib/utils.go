package lib

import "strings"

func StripCmdHead(cmd string) []string {
	return strings.Fields(cmd)[1:]
}
