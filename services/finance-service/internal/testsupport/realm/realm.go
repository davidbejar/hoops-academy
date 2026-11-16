// Package realm is a stand-in for the Keycloak realm in tests: an RSA key, the discovery document and the JWKS
// served over HTTP, and access tokens signed with that key.
package realm

import (
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Audience is finance-service's token audience.
const Audience = "finance-service"

// Realm is a running test realm.
type Realm struct {
	Server *httptest.Server
	key    *rsa.PrivateKey
	kid    string
	// CertsCalls counts the JWKS fetches.
	CertsCalls int
}

// Start serves <url>/.well-known/openid-configuration and <url>/protocol/openid-connect/certs until the test ends.
func Start(t testing.TB) *Realm {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	r := &Realm{key: key, kid: "test-key"}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /.well-known/openid-configuration", func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"issuer": r.Issuer()})
	})
	mux.HandleFunc("GET /protocol/openid-connect/certs", func(w http.ResponseWriter, _ *http.Request) {
		r.CertsCalls++
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": []map[string]string{{
			"kty": "RSA", "kid": r.kid, "use": "sig", "alg": "RS256",
			"n": base64.RawURLEncoding.EncodeToString(r.key.N.Bytes()),
			"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(r.key.E)).Bytes()),
		}}})
	})
	r.Server = httptest.NewServer(mux)
	t.Cleanup(r.Server.Close)
	return r
}

// URL is the realm's base URL (OIDC_AUTH_SERVER_URL).
func (r *Realm) URL() string { return r.Server.URL }

// Issuer is the iss of the realm's tokens.
func (r *Realm) Issuer() string { return r.Server.URL }

// Token is an access token for subject with audience finance-service, valid for five minutes.
func (r *Realm) Token(t testing.TB, subject string) string {
	return r.Sign(t, jwt.MapClaims{
		"sub": subject, "aud": []string{Audience}, "iss": r.Issuer(),
		"exp": time.Now().Add(5 * time.Minute).Unix(), "iat": time.Now().Unix(),
	})
}

// Sign signs claims with the realm's key (any claims: tests build wrong tokens with it).
func (r *Realm) Sign(t testing.TB, claims jwt.MapClaims) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	token.Header["kid"] = r.kid
	signed, err := token.SignedString(r.key)
	if err != nil {
		t.Fatal(err)
	}
	return signed
}

// Rotate replaces the signing key (a new kid); tokens signed before stop verifying.
func (r *Realm) Rotate(t testing.TB) {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	r.key, r.kid = key, r.kid+"-next"
}
