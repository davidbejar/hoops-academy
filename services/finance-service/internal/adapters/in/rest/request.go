package rest

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
)

// MaxBodyBytes is the largest JSON body accepted (413 REQUEST_TOO_LARGE above); finance requests are small.
const MaxBodyBytes = 64 << 10

// decode reads exactly one JSON object of r into into: application/json only (415), MaxBodyBytes at most (413), no
// unknown properties (400, the contract's additionalProperties: false). On failure it has answered.
func decode(w http.ResponseWriter, r *http.Request, into any) bool {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		writeProblem(w, r, unsupportedMedia, "", "the body must be application/json", nil)
		return false
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, MaxBodyBytes))
	var tooBig *http.MaxBytesError
	if errors.As(err, &tooBig) {
		writeProblem(w, r, tooLarge, "REQUEST_TOO_LARGE", "the body is larger than 64 KiB", nil)
		return false
	}
	if err != nil {
		writeProblem(w, r, badRequest, "MALFORMED_JSON", "the body cannot be read", nil)
		return false
	}
	decoder := json.NewDecoder(bytes.NewReader(body))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(into); err != nil {
		writeDecodeError(w, r, err)
		return false
	}
	if decoder.More() {
		writeProblem(w, r, badRequest, "MALFORMED_JSON", "the body must hold one JSON object", nil)
		return false
	}
	return true
}

// writeDecodeError names the field of a type mismatch or an unknown property, never the value.
func writeDecodeError(w http.ResponseWriter, r *http.Request, err error) {
	var typeError *json.UnmarshalTypeError
	switch {
	case errors.As(err, &typeError):
		field := typeError.Field
		if field == "" {
			field = "body"
		}
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", []violation{{field, "INVALID_TYPE", messageOf("INVALID_TYPE")}})
	case strings.HasPrefix(err.Error(), "json: unknown field "):
		field := strings.Trim(strings.TrimPrefix(err.Error(), "json: unknown field "), `"`)
		writeProblem(w, r, validation, "VALIDATION_FAILED", "",
			[]violation{{safeField(field), "UNKNOWN_PROPERTY", messageOf("UNKNOWN_PROPERTY")}})
	default:
		writeProblem(w, r, badRequest, "MALFORMED_JSON", "the body is not valid JSON", nil)
	}
}

// safeField keeps a property name only when it looks like one (a client's key could carry anything).
func safeField(name string) string {
	if len(name) > 40 {
		return "body"
	}
	for _, c := range name {
		letter := c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z'
		if !letter && (c < '0' || c > '9') && c != '_' {
			return "body"
		}
	}
	return name
}

// query reads query parameters; the first invalid one is answered with 400 naming it.
type query struct {
	values     url.Values
	violations []violation
}

func newQuery(r *http.Request) *query { return &query{values: r.URL.Query()} }

func (q *query) invalid(name string) {
	q.violations = append(q.violations, violation{name, "INVALID", messageOf("INVALID")})
}

func (q *query) uuid(name string) *domain.UUID {
	raw := q.values.Get(name)
	if raw == "" {
		return nil
	}
	id, err := domain.ParseUUID(raw)
	if err != nil {
		q.invalid(name)
		return nil
	}
	return &id
}

func (q *query) boolean(name string) bool {
	switch q.values.Get(name) {
	case "", "false":
		return false
	case "true":
		return true
	default:
		q.invalid(name)
		return false
	}
}

func (q *query) integer(name string, fallback, low, high int) int {
	raw := q.values.Get(name)
	if raw == "" {
		return fallback
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < low || n > high {
		q.invalid(name)
		return fallback
	}
	return n
}

// page reads page (0-based) and size (1..200, default 50).
func (q *query) page() application.Page {
	return application.Page{Index: q.integer("page", 0, 0, 1<<20), Size: q.integer("size", 50, 1, 200)}
}

// failed answers 400 when a parameter was invalid.
func (q *query) failed(w http.ResponseWriter, r *http.Request) bool {
	if len(q.violations) == 0 {
		return false
	}
	writeProblem(w, r, validation, "VALIDATION_FAILED", "", q.violations)
	return true
}

// pathID reads a uuid path parameter (400 when malformed).
func pathID(w http.ResponseWriter, r *http.Request, raw, name string) (domain.UUID, bool) {
	id, err := domain.ParseUUID(raw)
	if err != nil {
		writeProblem(w, r, validation, "VALIDATION_FAILED", "", []violation{{name, "INVALID", messageOf("INVALID")}})
		return domain.UUID{}, false
	}
	return id, true
}

// writeJSON answers a JSON body.
func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
