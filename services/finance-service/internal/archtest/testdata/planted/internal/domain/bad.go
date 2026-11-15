// Package domain is a planted violation for the layering check (never built: testdata is ignored by go).
package domain

import (
	"errors"
	"net/http"

	"github.com/jackc/pgx/v5"

	"hoopsacademy.local/finance/internal/application"
)

var _ = errors.New
var _ = http.MethodGet
var _ = pgx.ErrNoRows
var _ = application.X
