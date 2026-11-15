// Package db holds the schema migrations of finance-service (files V<nn>__<snake_case>.sql, one concern per file),
// compiled into the binary and applied at start as finance_migrator (ADR-0055). Numbers: V1-V9 WP118, V10-V19 WP119,
// V20-V29 WP123.
package db

import "embed"

// Migrations are the files of db/migration.
//
//go:embed migration/*.sql
var Migrations embed.FS
