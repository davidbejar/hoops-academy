// Package ids makes UUIDs version 7 (RFC 9562: a millisecond timestamp, then random bits), so new rows sort roughly
// by creation and index pages stay warm.
package ids

import (
	"crypto/rand"
	"encoding/binary"
	"time"

	"hoopsacademy.local/finance/internal/domain"
)

// V7 implements application.IDs.
type V7 struct {
	// Now is the clock (time.Now when nil).
	Now func() time.Time
}

// New returns a fresh UUIDv7.
func (g V7) New() domain.UUID {
	now := time.Now
	if g.Now != nil {
		now = g.Now
	}
	var id domain.UUID
	_, _ = rand.Read(id[:]) // crypto/rand.Read never fails (Go 1.24+)
	var millis [8]byte
	binary.BigEndian.PutUint64(millis[:], uint64(now().UnixMilli()))
	copy(id[:6], millis[2:])
	id[6] = id[6]&0x0f | 0x70
	id[8] = id[8]&0x3f | 0x80
	return id
}
