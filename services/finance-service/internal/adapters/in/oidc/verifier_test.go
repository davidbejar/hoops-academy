package oidc

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"hoopsacademy.local/finance/internal/testsupport/realm"
)

func verifier(r *realm.Realm) *Verifier {
	return NewVerifier(Config{AuthServerURL: r.URL(), Audience: realm.Audience})
}

func reason(t *testing.T, err error) string {
	t.Helper()
	var refused *Refused
	if !errors.As(err, &refused) {
		t.Fatalf("expected a refusal, got %v", err)
	}
	return refused.Reason
}

func TestAValidTokenOfTheRealmGivesItsSubject(t *testing.T) {
	r := realm.Start(t)

	claims, err := verifier(r).Verify(context.Background(), r.Token(t, "sub-1"))
	if err != nil || claims.Subject != "sub-1" {
		t.Errorf("got %+v %v", claims, err)
	}
}

func TestTokensAreRefusedWithTheirReason(t *testing.T) {
	r := realm.Start(t)
	v := verifier(r)
	now := time.Now()
	valid := func() jwt.MapClaims {
		return jwt.MapClaims{"sub": "s", "aud": realm.Audience, "iss": r.Issuer(), "exp": now.Add(time.Minute).Unix()}
	}
	with := func(key string, value any) jwt.MapClaims {
		c := valid()
		if value == nil {
			delete(c, key)
		} else {
			c[key] = value
		}
		return c
	}
	cases := map[string]string{
		"expired":           r.Sign(t, with("exp", now.Add(-time.Minute).Unix())),
		"not_yet_valid":     r.Sign(t, with("nbf", now.Add(time.Hour).Unix())),
		"audience (other)":  r.Sign(t, with("aud", "core-service")),
		"audience (none)":   r.Sign(t, with("aud", nil)),
		"issuer":            r.Sign(t, with("iss", "http://elsewhere/realms/academy")),
		"no_sub":            r.Sign(t, with("sub", nil)),
		"invalid (no exp)":  r.Sign(t, with("exp", nil)),
		"invalid (garbage)": "not.a.token",
	}
	for want, token := range cases {
		got := reason(t, errOf(v.Verify(context.Background(), token)))
		if got != firstWord(want) {
			t.Errorf("%s: got reason %s", want, got)
		}
	}
	unsigned := jwt.NewWithClaims(jwt.SigningMethodNone, valid())
	none, _ := unsigned.SignedString(jwt.UnsafeAllowNoneSignatureType)
	if got := reason(t, errOf(v.Verify(context.Background(), none))); got != "signature" {
		t.Errorf("alg none: %s", got)
	}
	other := realm.Start(t)
	if got := reason(t, errOf(v.Verify(context.Background(), other.Sign(t, valid())))); got != "signature" {
		t.Errorf("another key with the same kid: %s", got)
	}
}

// The clock leeway is the Java services' (X-11): none. They set no quarkus.oidc.token.lifespan-grace, and quarkus-oidc
// then leaves jose4j's allowed clock skew at its default of 0 seconds; a token expired two seconds ago is refused.
func TestTheClockLeewayIsTheJavaServicesZeroSeconds(t *testing.T) {
	r := realm.Start(t)
	now := time.Now()
	claims := func(key string, at time.Time) jwt.MapClaims {
		c := jwt.MapClaims{"sub": "s", "aud": realm.Audience, "iss": r.Issuer(), "exp": now.Add(time.Minute).Unix()}
		c[key] = at.Unix()
		return c
	}
	if got := reason(t, errOf(verifier(r).Verify(context.Background(), r.Sign(t, claims("exp", now.Add(-2*time.Second)))))); got != "expired" {
		t.Errorf("expired two seconds ago: %s", got)
	}
	if got := reason(t, errOf(verifier(r).Verify(context.Background(), r.Sign(t, claims("nbf", now.Add(2*time.Second)))))); got != "not_yet_valid" {
		t.Errorf("valid in two seconds: %s", got)
	}
}

func TestARotatedKeyIsFetchedOnceForItsNewKeyID(t *testing.T) {
	r := realm.Start(t)
	v := NewVerifier(Config{AuthServerURL: r.URL(), Audience: realm.Audience, MinRefetch: time.Nanosecond})
	if _, err := v.Verify(context.Background(), r.Token(t, "a")); err != nil {
		t.Fatal(err)
	}
	r.Rotate(t)

	if _, err := v.Verify(context.Background(), r.Token(t, "b")); err != nil {
		t.Errorf("after rotation: %v", err)
	}
	calls := r.CertsCalls
	_, _ = v.Verify(context.Background(), r.Token(t, "c"))
	if r.CertsCalls != calls {
		t.Error("a known key id was fetched again")
	}
}

func TestAnUnknownKeyIDWithinTheRefetchIntervalIsRefusedWithoutAFetch(t *testing.T) {
	r := realm.Start(t)
	v := verifier(r)
	_, _ = v.Verify(context.Background(), r.Token(t, "a"))
	r.Rotate(t)
	calls := r.CertsCalls

	if got := reason(t, errOf(v.Verify(context.Background(), r.Token(t, "b")))); got != "signature" || r.CertsCalls != calls {
		t.Errorf("got %s after %d fetches", got, r.CertsCalls-calls)
	}
}

func TestAnUnreachableRealmIsUnavailableNotARefusal(t *testing.T) {
	r := realm.Start(t)
	token := r.Token(t, "s")
	r.Server.Close()

	_, err := verifier(r).Verify(context.Background(), token)
	if !errors.Is(err, ErrUnavailable) {
		t.Errorf("got %v", err)
	}
}

func TestAConfiguredIssuerReplacesDiscovery(t *testing.T) {
	r := realm.Start(t)
	v := NewVerifier(Config{AuthServerURL: r.URL(), Audience: realm.Audience, Issuer: "http://public/realms/academy"})

	if got := reason(t, errOf(v.Verify(context.Background(), r.Token(t, "s")))); got != "issuer" {
		t.Errorf("got %s", got)
	}
}

func firstWord(s string) string {
	for i, c := range s {
		if c == ' ' {
			return s[:i]
		}
	}
	return s
}

func errOf[T any](_ T, err error) error { return err }
