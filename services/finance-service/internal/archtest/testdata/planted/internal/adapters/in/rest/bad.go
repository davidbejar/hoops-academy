// Package rest is a planted violation for the layering check (never built: testdata is ignored by go).
package rest

import "hoopsacademy.local/finance/internal/testsupport/pgtest"

var _ = pgtest.X
