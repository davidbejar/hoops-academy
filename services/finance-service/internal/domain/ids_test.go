package domain

import (
	"errors"
	"testing"
)

func TestUUIDsRoundTripInTheirCanonicalForm(t *testing.T) {
	const text = "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d11"
	id, err := ParseUUID(text)
	if err != nil {
		t.Fatal(err)
	}
	if id.String() != text {
		t.Errorf("got %s", id)
	}
	upper, err := ParseUUID("6F1C8A52-0D8E-4F5E-9A51-2A8F0C3B7D11")
	if err != nil || upper != id {
		t.Errorf("upper case: %v %v", upper, err)
	}
}

func TestMalformedUUIDsAreRefused(t *testing.T) {
	for _, text := range []string{
		"", "6f1c8a52", "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d1", "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d111",
		"6f1c8a520d8e-4f5e-9a51-2a8f0c3b7d11-", "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7dzz", "{6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d}",
	} {
		if _, err := ParseUUID(text); !errors.Is(err, ErrInvalidUUID) {
			t.Errorf("%q: %v", text, err)
		}
	}
}

func TestTheNilUUIDIsNeverATenant(t *testing.T) {
	if _, err := ParseTenantID("00000000-0000-0000-0000-000000000000"); !errors.Is(err, ErrNilTenant) {
		t.Errorf("nil tenant accepted: %v", err)
	}
	if _, err := ParseTenantID("nope"); !errors.Is(err, ErrInvalidUUID) {
		t.Errorf("malformed tenant: %v", err)
	}
	tenant, err := ParseTenantID("6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d11")
	if err != nil || tenant.IsZero() || tenant.String() != "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d11" {
		t.Errorf("tenant: %v %v", tenant, err)
	}
	if tenant.UUID().String() != tenant.String() {
		t.Error("UUID() and String() disagree")
	}
	if !(TenantID{}).IsZero() {
		t.Error("the zero TenantID must report IsZero")
	}
}

func TestIdentifiersPrintTheirUUID(t *testing.T) {
	id, _ := ParseUUID("6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d11")
	for _, s := range []string{
		FeePlanID(id).String(), PersonID(id).String(), SeasonID(id).String(), TeamID(id).String(),
		AgeCategoryID(id).String(),
	} {
		if s != id.String() {
			t.Errorf("got %s", s)
		}
	}
}
