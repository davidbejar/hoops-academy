// Package oidc verifies the realm's access tokens for finance-service (ADR-0034): RS256 only, signed by a key of the
// realm's JWKS (read on first use and again for an unknown key id, at most every 30 s), issuer from the realm's
// discovery document unless configured, audience finance-service, an expiry, a subject.
package oidc

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Config is where the realm is and what the tokens must say.
type Config struct {
	AuthServerURL string // e.g. http://keycloak:8080/auth/realms/academy (as the pod reaches it)
	Issuer        string // empty: the discovery document's issuer (Keycloak's public hostname)
	Audience      string
	// MinRefetch is the least time between two JWKS fetches for unknown key ids (0: 30 s).
	MinRefetch time.Duration
}

// Claims are what the service uses of a verified token.
type Claims struct {
	Subject string
}

// Refused is a token that fails verification; Reason is one of expired, not_yet_valid, audience, signature, issuer,
// invalid, no_sub (the security event's reason).
type Refused struct{ Reason string }

func (r *Refused) Error() string { return "token refused: " + r.Reason }

// ErrUnavailable is a realm that cannot be read (keys or discovery): 503, never a refusal.
var ErrUnavailable = errors.New("the realm is unavailable")

// Verifier verifies access tokens.
type Verifier struct {
	config Config
	client *http.Client

	mu        sync.Mutex
	keys      map[string]*rsa.PublicKey
	issuer    string
	lastFetch time.Time
}

const defaultMinRefetch = 30 * time.Second

// Leeway is the clock skew allowed on exp, nbf and iat: none, as the Java services (they set no
// quarkus.oidc.token.lifespan-grace, so quarkus-oidc leaves jose4j's allowed clock skew at 0 seconds; X-11).
const Leeway = 0 * time.Second

// NewVerifier reads the realm lazily.
func NewVerifier(config Config) *Verifier {
	if config.MinRefetch <= 0 {
		config.MinRefetch = defaultMinRefetch
	}
	return &Verifier{config: config, client: &http.Client{Timeout: 5 * time.Second}, keys: map[string]*rsa.PublicKey{}}
}

// Verify checks raw and returns its claims, a *Refused, or ErrUnavailable.
func (v *Verifier) Verify(ctx context.Context, raw string) (Claims, error) {
	issuer, err := v.issuerOf(ctx)
	if err != nil {
		return Claims{}, err
	}
	var unavailable error
	token, err := jwt.Parse(raw, func(token *jwt.Token) (any, error) {
		kid, _ := token.Header["kid"].(string)
		key, err := v.key(ctx, kid)
		if errors.Is(err, ErrUnavailable) {
			unavailable = err
		}
		return key, err
	},
		jwt.WithValidMethods([]string{"RS256"}), jwt.WithIssuer(issuer), jwt.WithExpirationRequired(),
		jwt.WithLeeway(Leeway))
	if unavailable != nil {
		return Claims{}, unavailable
	}
	if err != nil {
		return Claims{}, &Refused{Reason: reasonOf(err)}
	}
	audiences, err := token.Claims.GetAudience()
	if err != nil || !slices.Contains(audiences, v.config.Audience) {
		return Claims{}, &Refused{Reason: "audience"}
	}
	subject, err := token.Claims.GetSubject()
	if err != nil || subject == "" {
		return Claims{}, &Refused{Reason: "no_sub"}
	}
	return Claims{Subject: subject}, nil
}

func reasonOf(err error) string {
	switch {
	case errors.Is(err, jwt.ErrTokenExpired):
		return "expired"
	case errors.Is(err, jwt.ErrTokenNotValidYet):
		return "not_yet_valid"
	case errors.Is(err, jwt.ErrTokenSignatureInvalid), errors.Is(err, errUnknownKey):
		return "signature"
	case errors.Is(err, jwt.ErrTokenInvalidIssuer):
		return "issuer"
	default:
		return "invalid"
	}
}

var errUnknownKey = errors.New("unknown key id")

func (v *Verifier) issuerOf(ctx context.Context) (string, error) {
	if v.config.Issuer != "" {
		return v.config.Issuer, nil
	}
	v.mu.Lock()
	defer v.mu.Unlock()
	if v.issuer != "" {
		return v.issuer, nil
	}
	var discovery struct {
		Issuer string `json:"issuer"`
	}
	if err := v.getJSON(ctx, "/.well-known/openid-configuration", &discovery); err != nil {
		return "", err
	}
	if discovery.Issuer == "" {
		return "", fmt.Errorf("%w: discovery without issuer", ErrUnavailable)
	}
	v.issuer = discovery.Issuer
	return v.issuer, nil
}

// key returns the key of kid, fetching the JWKS when kid is unknown (at most every refetchInterval).
func (v *Verifier) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	if key, ok := v.keys[kid]; ok {
		return key, nil
	}
	if !v.lastFetch.IsZero() && time.Since(v.lastFetch) < v.config.MinRefetch {
		return nil, errUnknownKey
	}
	keys, err := v.fetchKeys(ctx)
	if err != nil {
		return nil, err
	}
	v.keys, v.lastFetch = keys, time.Now()
	if key, ok := v.keys[kid]; ok {
		return key, nil
	}
	return nil, errUnknownKey
}

type jwk struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
}

func (v *Verifier) fetchKeys(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	var set struct {
		Keys []jwk `json:"keys"`
	}
	if err := v.getJSON(ctx, "/protocol/openid-connect/certs", &set); err != nil {
		return nil, err
	}
	keys := map[string]*rsa.PublicKey{}
	for _, k := range set.Keys {
		if k.Kty != "RSA" || (k.Use != "" && k.Use != "sig") {
			continue
		}
		n, errN := base64.RawURLEncoding.DecodeString(k.N)
		e, errE := base64.RawURLEncoding.DecodeString(k.E)
		if errN != nil || errE != nil || len(e) > 4 {
			continue
		}
		exponent := int(new(big.Int).SetBytes(e).Int64())
		keys[k.Kid] = &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: exponent}
	}
	return keys, nil
}

func (v *Verifier) getJSON(ctx context.Context, path string, into any) error {
	url := strings.TrimSuffix(v.config.AuthServerURL, "/") + path
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
	response, err := v.client.Do(request)
	if err != nil {
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("%w: %s answered %d", ErrUnavailable, path, response.StatusCode)
	}
	if err := json.NewDecoder(response.Body).Decode(into); err != nil {
		return fmt.Errorf("%w: %s: %w", ErrUnavailable, path, err)
	}
	return nil
}
