package ids

import (
	"testing"
	"time"
)

func TestV7IdsCarryTheirVersionVariantAndTime(t *testing.T) {
	at := time.UnixMilli(0x0190b6a0_1234)
	g := V7{Now: func() time.Time { return at }}

	a, b := g.New(), g.New()
	if a == b {
		t.Fatal("two equal ids")
	}
	text := a.String()
	if text[:13] != "0190b6a0-1234" || text[14] != '7' || (text[19] != '8' && text[19] != '9' && text[19] != 'a' && text[19] != 'b') {
		t.Errorf("not a v7 of that millisecond: %s", text)
	}
	if V7.New(V7{}).IsZero() {
		t.Error("the default clock made a nil id")
	}
}
