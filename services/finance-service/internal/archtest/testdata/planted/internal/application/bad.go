// Package application is a planted violation for the layering check (never built: testdata is ignored by go).
package application

import (
	"context"
	"database/sql"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/platform"
)

var _ = context.Background
var _ = sql.ErrNoRows
var _ = persistence.X
var _ = domain.X
var _ = platform.X
