// Package rest is the HTTP adapter of finance-service: the routes of finance.yaml, the authentication and tenant
// filter, Problem+JSON for every error (no stack traces, no request values), health, metrics and security headers.
package rest

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"go.opentelemetry.io/otel/trace"

	"hoopsacademy.local/finance/internal/domain"
)

// problemType is one of common-quarkus' ProblemType values (type urn:hoops:problem:<slug>).
type problemType struct {
	status      int
	title, slug string
}

var (
	badRequest       = problemType{400, "Bad Request", "bad-request"}
	validation       = problemType{400, "Validation Failed", "validation"}
	unauthorized     = problemType{401, "Unauthorized", "unauthorized"}
	forbidden        = problemType{403, "Forbidden", "forbidden"}
	notFound         = problemType{404, "Not Found", "not-found"}
	conflict         = problemType{409, "Conflict", "conflict"}
	tooLarge         = problemType{413, "Payload Too Large", "payload-too-large"}
	unsupportedMedia = problemType{415, "Unsupported Media Type", "unsupported-media-type"}
	ruleViolation    = problemType{422, "Domain Rule Violation", "domain-rule-violation"}
	internalError    = problemType{500, "Internal Server Error", "internal-error"}
	notImplemented   = problemType{501, "Not Implemented", "not-implemented"}
	unavailable      = problemType{503, "Service Unavailable", "upstream-unavailable"}
)

type violation struct {
	Field   string `json:"field,omitempty"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

type problem struct {
	Type       string      `json:"type"`
	Title      string      `json:"title"`
	Status     int         `json:"status"`
	Detail     string      `json:"detail,omitempty"`
	Instance   string      `json:"instance,omitempty"`
	TraceID    string      `json:"traceId,omitempty"`
	Code       string      `json:"code,omitempty"`
	Violations []violation `json:"violations,omitempty"`
}

// writeProblem answers application/problem+json. detail is written by the service, never copied from the request.
func writeProblem(w http.ResponseWriter, r *http.Request, t problemType, code, detail string, violations []violation) {
	body := problem{
		Type: "urn:hoops:problem:" + t.slug, Title: t.title, Status: t.status, Detail: detail,
		Instance: r.URL.EscapedPath(), Code: code, Violations: violations,
	}
	if span := trace.SpanContextFromContext(r.Context()); span.HasTraceID() {
		body.TraceID = span.TraceID().String()
	}
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(t.status)
	_ = json.NewEncoder(w).Encode(body)
}

func violationsOf(list []domain.Violation) []violation {
	out := make([]violation, len(list))
	for i, v := range list {
		out[i] = violation{Field: v.Field, Code: v.Code, Message: messageOf(v.Code)}
	}
	return out
}

// messageOf is a fixed text per code: a violation never repeats the value it refuses (privacy finding P-11).
func messageOf(code string) string {
	switch code {
	case "REQUIRED":
		return "is required"
	case "TOO_LONG":
		return "is too long"
	case "OUT_OF_RANGE":
		return "is out of range"
	case "UNKNOWN_PROPERTY":
		return "is not a property of this request"
	case "INVALID_TYPE":
		return "has the wrong type"
	default:
		return "is not valid"
	}
}

// writeError maps an error of the use cases to its Problem: the domain's kinds to 400/403/404/409/422, anything else
// to 500 (logged without the request).
func (h *handler) writeError(w http.ResponseWriter, r *http.Request, err error) {
	var e *domain.Error
	if !errors.As(err, &e) {
		h.log.ErrorContext(r.Context(), "request failed", slog.String("route", routeOf(r)), slog.String("error", err.Error()))
		writeProblem(w, r, internalError, "", "", nil)
		return
	}
	switch e.Kind {
	case domain.KindInvalid:
		writeProblem(w, r, validation, e.Code, "", violationsOf(e.Violations))
	case domain.KindNotFound:
		writeProblem(w, r, notFound, "", "", nil)
	case domain.KindForbidden:
		h.deny(r, e)
		writeProblem(w, r, forbidden, "", "", nil)
	case domain.KindConflict:
		writeProblem(w, r, conflict, e.Code, e.Detail, nil)
	default:
		writeProblem(w, r, ruleViolation, e.Code, e.Detail, nil)
	}
}
