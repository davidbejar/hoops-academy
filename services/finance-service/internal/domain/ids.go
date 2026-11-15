// Package domain holds finance-service's rules: identities, money, cadences and periods, fee plans, roles and the
// finance authorisation matrix. It imports nothing but a few standard packages (internal/archtest).
package domain

import (
	"errors"
	"strings"
)

// UUID is a 128-bit identifier in its canonical lower-case text form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".
type UUID [16]byte

// ErrInvalidUUID is returned for text that is not a canonical UUID.
var ErrInvalidUUID = errors.New("not a UUID")

const hexDigits = "0123456789abcdef"

// ParseUUID reads the canonical form (upper-case hex digits are accepted, as Java's UUID.fromString does).
func ParseUUID(text string) (UUID, error) {
	var id UUID
	if len(text) != 36 || text[8] != '-' || text[13] != '-' || text[18] != '-' || text[23] != '-' {
		return id, ErrInvalidUUID
	}
	hex := strings.ToLower(strings.ReplaceAll(text, "-", ""))
	for i := range 16 {
		high, low := strings.IndexByte(hexDigits, hex[2*i]), strings.IndexByte(hexDigits, hex[2*i+1])
		if high < 0 || low < 0 {
			return UUID{}, ErrInvalidUUID
		}
		id[i] = byte(high<<4 | low)
	}
	return id, nil
}

// String is the canonical lower-case form.
func (id UUID) String() string {
	var out [36]byte
	j := 0
	for i, b := range id {
		if i == 4 || i == 6 || i == 8 || i == 10 {
			out[j] = '-'
			j++
		}
		out[j], out[j+1] = hexDigits[b>>4], hexDigits[b&0x0f]
		j += 2
	}
	return string(out[:])
}

// IsZero reports the nil UUID.
func (id UUID) IsZero() bool { return id == UUID{} }

// TenantID identifies an academy. It is never the nil UUID: a nil tenant must never be bound.
type TenantID struct{ value UUID }

// ErrNilTenant is returned for the nil UUID as a tenant.
var ErrNilTenant = errors.New("the nil UUID is not a tenant")

// NewTenantID wraps a UUID; the nil UUID is refused.
func NewTenantID(id UUID) (TenantID, error) {
	if id.IsZero() {
		return TenantID{}, ErrNilTenant
	}
	return TenantID{id}, nil
}

// ParseTenantID reads a tenant id from its text form.
func ParseTenantID(text string) (TenantID, error) {
	id, err := ParseUUID(text)
	if err != nil {
		return TenantID{}, err
	}
	return NewTenantID(id)
}

// UUID is the tenant's identifier.
func (t TenantID) UUID() UUID { return t.value }

// String is the canonical text form.
func (t TenantID) String() string { return t.value.String() }

// IsZero reports an unset TenantID (the zero value of the type).
func (t TenantID) IsZero() bool { return t.value.IsZero() }

// FeePlanID identifies a fee plan.
type FeePlanID UUID

// String is the canonical text form.
func (id FeePlanID) String() string { return UUID(id).String() }

// PersonID identifies a member of an academy (core's person).
type PersonID UUID

// String is the canonical text form.
func (id PersonID) String() string { return UUID(id).String() }

// SeasonID identifies a season of an academy (core's season).
type SeasonID UUID

// String is the canonical text form.
func (id SeasonID) String() string { return UUID(id).String() }

// TeamID identifies a team (core's team).
type TeamID UUID

// String is the canonical text form.
func (id TeamID) String() string { return UUID(id).String() }

// AgeCategoryID identifies an age category (core's age category).
type AgeCategoryID UUID

// String is the canonical text form.
func (id AgeCategoryID) String() string { return UUID(id).String() }
