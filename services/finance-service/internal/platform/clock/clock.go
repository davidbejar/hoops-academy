// Package clock is the service's clock: UTC, to the microsecond PostgreSQL keeps.
package clock

import "time"

// System implements application.Clock with the system time.
type System struct{}

// Now is the current time in UTC, truncated to microseconds (what a timestamptz column stores), so a value read back
// equals the value written.
func (System) Now() time.Time { return time.Now().UTC().Truncate(time.Microsecond) }
