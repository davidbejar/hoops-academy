package clock

import (
	"testing"
	"time"
)

func TestTheSystemClockIsUTCToTheMicrosecond(t *testing.T) {
	before := time.Now().Add(-time.Second)
	now := System{}.Now()
	if now.Location() != time.UTC || now.Nanosecond()%1000 != 0 || now.Before(before) {
		t.Errorf("got %s", now.Format(time.RFC3339Nano))
	}
}
