package rest

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"slices"
	"strings"

	"hoopsacademy.local/finance/internal/adapters/in/oidc"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/platform/security"
)

// TokenVerifier verifies bearer tokens (oidc.Verifier).
type TokenVerifier interface {
	Verify(ctx context.Context, raw string) (oidc.Claims, error)
}

// Deps are what the handler needs.
type Deps struct {
	Finance     *application.Finance
	Verifier    TokenVerifier
	Security    *security.Events
	Log         *slog.Logger
	CORSOrigins []string
	// Ready reports the readiness checks (database); nil = always ready.
	Ready func(ctx context.Context) error
	// Metrics adds more Prometheus text to /q/metrics (e.g. the replica consumer's); nil = none.
	Metrics func(w http.ResponseWriter)
}

type handler struct {
	Deps
	log *slog.Logger
}

const tenantHeader = "X-Tenant-Id"

// NewHandler serves finance.yaml's operations under /api/finance/**, and /q/health*, /q/metrics.
func NewHandler(d Deps) http.Handler {
	h := &handler{Deps: d, log: d.Log}
	mux := http.NewServeMux()
	h.routes(mux)
	h.health(mux)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { writeProblem(w, r, notFound, "", "", nil) })
	return h.withHeaders(mux)
}

// memberHandler serves a request of a member of the requested academy.
type memberHandler func(w http.ResponseWriter, r *http.Request, caller domain.Membership)

// api wraps a tenant-scoped operation: authentication (401), the tenant header (400), membership in that tenant
// (404, never 403), then the operation. route is the contract's path template (security events, logs).
func (h *handler) api(route string, serve memberHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r = r.WithContext(context.WithValue(r.Context(), routeKey{}, r.Method+" "+route))
		subject, ok := h.authenticate(w, r)
		if !ok {
			return
		}
		caller, ok := h.member(w, r, subject)
		if !ok {
			return
		}
		serve(w, r, caller)
	}
}

type routeKey struct{}

func routeOf(r *http.Request) string {
	if route, ok := r.Context().Value(routeKey{}).(string); ok {
		return route
	}
	return r.Method + " " + r.URL.Path
}

func (h *handler) authenticate(w http.ResponseWriter, r *http.Request) (string, bool) {
	raw, found := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
	if !found || strings.TrimSpace(raw) == "" {
		h.Security.Deny(r.Context(), security.Denial{Kind: security.Unauthenticated, Resource: routeOf(r),
			Reason: "no credentials"})
		w.Header().Set("WWW-Authenticate", "Bearer")
		writeProblem(w, r, unauthorized, "", "", nil)
		return "", false
	}
	claims, err := h.Verifier.Verify(r.Context(), strings.TrimSpace(raw))
	var refused *oidc.Refused
	switch {
	case errors.As(err, &refused):
		h.Security.Deny(r.Context(), security.Denial{Kind: security.InvalidToken, Resource: routeOf(r),
			Reason: refused.Reason})
		w.Header().Set("WWW-Authenticate", "Bearer")
		writeProblem(w, r, unauthorized, "", "", nil)
		return "", false
	case err != nil:
		h.log.WarnContext(r.Context(), "token keys unavailable", slog.String("error", err.Error()))
		writeProblem(w, r, unavailable, "AUTH_UNAVAILABLE", "the identity provider cannot be reached; retry", nil)
		return "", false
	}
	return claims.Subject, true
}

func (h *handler) member(w http.ResponseWriter, r *http.Request, subject string) (domain.Membership, bool) {
	raw := r.Header.Get(tenantHeader)
	if strings.TrimSpace(raw) == "" {
		writeProblem(w, r, badRequest, "", "Header "+tenantHeader+" is required", nil)
		return domain.Membership{}, false
	}
	tenant, err := domain.ParseTenantID(raw)
	if err != nil {
		writeProblem(w, r, badRequest, "", "Header "+tenantHeader+" must be a UUID", nil)
		return domain.Membership{}, false
	}
	caller, found, err := h.Finance.ResolveMembership(r.Context(), tenant, subject)
	if err != nil {
		h.writeError(w, r, err)
		return domain.Membership{}, false
	}
	if !found {
		h.Security.Deny(r.Context(), security.Denial{Kind: security.NotMember, Tenant: tenant.String(),
			Subject: subject, Resource: routeOf(r), Reason: "no membership in the requested tenant"})
		writeProblem(w, r, notFound, "", "", nil)
		return domain.Membership{}, false
	}
	if caller.Tenant() != tenant {
		h.Security.Deny(r.Context(), security.Denial{Kind: security.TenantMismatch, Tenant: tenant.String(),
			Subject: subject, Resource: routeOf(r), Reason: "membership resolved for another tenant"})
		writeProblem(w, r, notFound, "", "", nil)
		return domain.Membership{}, false
	}
	return caller, true
}

// deny records a member's refusal by a use case (403).
func (h *handler) deny(r *http.Request, e *domain.Error) {
	kind := security.FineGrained
	if e.Code == application.DeniedByRole {
		kind = security.Role
	}
	caller, _ := r.Context().Value(callerKey{}).(domain.Membership)
	h.Security.Deny(r.Context(), security.Denial{Kind: kind, Tenant: caller.Tenant().String(),
		Subject: caller.Subject(), Roles: caller.RoleNames(), Resource: routeOf(r), Reason: e.Detail})
}

type callerKey struct{}

// withCaller keeps the caller in the request context for deny.
func withCaller(r *http.Request, caller domain.Membership) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), callerKey{}, caller))
}

// withHeaders adds the security headers of common-quarkus to every answer outside /q/**, no-store to the API's
// (finance data is never cached), and answers CORS preflights of the allowed origins.
func (h *handler) withHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/q/") {
			header := w.Header()
			header.Set("X-Content-Type-Options", "nosniff")
			header.Set("X-Frame-Options", "DENY")
			header.Set("Referrer-Policy", "no-referrer")
			header.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
			header.Set("Cross-Origin-Resource-Policy", "same-origin")
			header.Set("Cache-Control", "no-store")
		}
		origin := r.Header.Get("Origin")
		allowed := origin != "" && slices.Contains(h.CORSOrigins, origin)
		if allowed {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Add("Vary", "Origin")
		}
		if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
			if allowed {
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE")
				w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Tenant-Id, Accept-Language")
				w.Header().Set("Access-Control-Max-Age", "600")
			}
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
