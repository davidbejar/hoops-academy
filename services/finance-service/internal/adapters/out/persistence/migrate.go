// Package persistence is the PostgreSQL adapter of finance-service: the migration runner, the tenant-bound
// transactions and the repositories (pgx, constant SQL with bound parameters only).
package persistence

import (
	"context"
	"errors"
	"io/fs"
)

// Migration is one file of db/migration.
type Migration struct {
	Version     int
	Description string
	Name        string
	SQL         string
	Checksum    int64
}

// LoadMigrations reads the files under migration/ of fsys.
func LoadMigrations(fsys fs.FS) ([]Migration, error) {
	return nil, errors.New("not implemented")
}

// Migrate applies the migrations of fsys not applied yet, connecting with url (finance_migrator).
func Migrate(ctx context.Context, url string, fsys fs.FS) (int, error) {
	return 0, errors.New("not implemented")
}
