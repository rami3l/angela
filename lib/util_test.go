package lib

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestStripCmdHead(t *testing.T) {
	cmd := "/cmd foo bar"
	longCmd := "/cmd@that_bot foo bar"
	expected := "foo bar"
	stripCmdHead := func(cmd string) string {
		return strings.Join(StripCmdHead(cmd), " ")
	}
	assert.Equal(t, expected, stripCmdHead(cmd))
	assert.Equal(t, expected, stripCmdHead(longCmd))
}
