package domain

import (
	"errors"
	"strings"
)

// ErrInvalid marks malformed input (a value that is not of its type); an *Error of KindInvalid matches it too.
var ErrInvalid = errors.New("invalid")

// Kind says what kind of refusal an Error is; the REST adapter maps each to a status (ADR-0055).
type Kind int

// The kinds of refusal.
const (
	KindInvalid   Kind = iota // 400 VALIDATION_FAILED: field violations
	KindNotFound              // 404
	KindForbidden             // 403: a member without the role or relation
	KindConflict              // 409: the state forbids it
	KindRule                  // 422: well-formed, but a rule refuses it
)

// Violation names a field (dotted path as in the request) and a machine code; never the value (privacy P-11).
type Violation struct {
	Field string
	Code  string
}

// Error is a refusal of the domain or the application, with a stable code in SCREAMING_SNAKE_CASE.
type Error struct {
	Kind       Kind
	Code       string
	Detail     string
	Violations []Violation
}

func (e *Error) Error() string {
	if e.Detail != "" {
		return e.Code + ": " + e.Detail
	}
	return e.Code
}

// Is lets errors.Is(err, ErrInvalid) match an invalid-input Error.
func (e *Error) Is(target error) bool { return target == ErrInvalid && e.Kind == KindInvalid }

// Conflict is a 409 refusal.
func Conflict(code, detail string) *Error {
	return &Error{Kind: KindConflict, Code: code, Detail: detail}
}

// RuleViolation is a 422 refusal.
func RuleViolation(code, detail string) *Error {
	return &Error{Kind: KindRule, Code: code, Detail: detail}
}

// NotFound is a 404 refusal.
func NotFound(detail string) *Error {
	return &Error{Kind: KindNotFound, Code: "NOT_FOUND", Detail: detail}
}

// Forbidden is a 403 refusal of a member; Code says which rule refused it.
func Forbidden(code, detail string) *Error {
	return &Error{Kind: KindForbidden, Code: code, Detail: detail}
}

// violations collects field violations and turns them into one invalid-input Error.
type violations []Violation

func (v *violations) add(field, code string) { *v = append(*v, Violation{Field: field, Code: code}) }

func (v violations) err() error {
	if len(v) == 0 {
		return nil
	}
	return &Error{Kind: KindInvalid, Code: "VALIDATION_FAILED", Violations: v}
}

// invalid is a single-field invalid-input Error.
func invalid(field, code string) error {
	return &Error{Kind: KindInvalid, Code: "VALIDATION_FAILED", Violations: []Violation{{field, code}}}
}

// codeOf is the violation code of a single-field Error, or INVALID.
func codeOf(err error) string {
	var e *Error
	if errors.As(err, &e) && len(e.Violations) == 1 {
		return e.Violations[0].Code
	}
	return "INVALID"
}

// textLength counts characters, not bytes.
func textLength(s string) int { return len([]rune(s)) }

// cleanText trims surrounding white space.
func cleanText(s string) string { return strings.TrimSpace(s) }
