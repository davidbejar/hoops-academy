// Package persistence is the PostgreSQL adapter of finance-service: the migration runner, the tenant-bound
// transactions and the repositories (pgx, constant SQL with bound parameters only).
package persistence

import (
	"context"
	"errors"
	"fmt"
	"hash/crc32"
	"io/fs"
	"path"
	"regexp"
	"sort"
	"strconv"

	"github.com/jackc/pgx/v5"
)

// Migration is one file of db/migration.
type Migration struct {
	Version     int
	Description string
	Name        string
	SQL         string
	Checksum    int64
}

// ErrMigration reports a migration file or history the runner refuses.
var ErrMigration = errors.New("migration")

var migrationName = regexp.MustCompile(`^V([1-9][0-9]*)__([a-z0-9]+(?:_[a-z0-9]+)*)\.sql$`)

const migrationDir = "migration"

// LoadMigrations reads the files under migration/ of fsys, named V<n>__<snake_case>.sql (Flyway's convention, as
// the Java services), in version order. A name off the convention or a version used twice is refused.
func LoadMigrations(fsys fs.FS) ([]Migration, error) {
	entries, err := fs.ReadDir(fsys, migrationDir)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", migrationDir, err)
	}
	byVersion := map[int]Migration{}
	for _, entry := range entries {
		match := migrationName.FindStringSubmatch(entry.Name())
		if match == nil || entry.IsDir() {
			return nil, fmt.Errorf("%w: %s is not V<n>__<snake_case>.sql", ErrMigration, entry.Name())
		}
		version, _ := strconv.Atoi(match[1])
		if other, ok := byVersion[version]; ok {
			return nil, fmt.Errorf("%w: version %d twice (%s, %s)", ErrMigration, version, other.Name, entry.Name())
		}
		content, err := fs.ReadFile(fsys, path.Join(migrationDir, entry.Name()))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", entry.Name(), err)
		}
		byVersion[version] = Migration{
			Version: version, Description: match[2], Name: entry.Name(), SQL: string(content),
			Checksum: int64(crc32.ChecksumIEEE(content)),
		}
	}
	migrations := make([]Migration, 0, len(byVersion))
	for _, m := range byVersion {
		migrations = append(migrations, m)
	}
	sort.Slice(migrations, func(i, j int) bool { return migrations[i].Version < migrations[j].Version })
	return migrations, nil
}

const (
	lockHistory   = "select pg_advisory_lock(hashtext('finance.schema_history'))"
	unlockHistory = "select pg_advisory_unlock(hashtext('finance.schema_history'))"
	createHistory = `create table if not exists finance.schema_history (
		version       integer primary key,
		description   text not null,
		checksum      bigint not null,
		installed_at  timestamptz not null default now())`
	// The default privileges of infra/db/init grant DML on every table of the schema to finance_app; the history is
	// the migrator's alone.
	revokeHistory = "revoke all on finance.schema_history from finance_app"
	readHistory   = "select version, checksum from finance.schema_history order by version"
	recordApplied = "insert into finance.schema_history (version, description, checksum) values ($1, $2, $3)"
)

// Migrate applies, as the role of url (finance_migrator), every migration of fsys not applied yet, each in its own
// transaction together with its history row, under an advisory lock so that two starting replicas take turns. An
// applied migration whose file changed, or a history version without a file, stops the start. Returns how many it
// applied.
func Migrate(ctx context.Context, url string, fsys fs.FS) (int, error) {
	migrations, err := LoadMigrations(fsys)
	if err != nil {
		return 0, err
	}
	conn, err := pgx.Connect(ctx, url)
	if err != nil {
		return 0, fmt.Errorf("connect as migrator: %w", err)
	}
	defer func() { _ = conn.Close(context.WithoutCancel(ctx)) }()
	if _, err := conn.Exec(ctx, lockHistory); err != nil {
		return 0, fmt.Errorf("lock schema history: %w", err)
	}
	defer func() { _, _ = conn.Exec(context.WithoutCancel(ctx), unlockHistory) }()
	for _, statement := range []string{createHistory, revokeHistory} {
		if _, err := conn.Exec(ctx, statement); err != nil {
			return 0, fmt.Errorf("schema history: %w", err)
		}
	}
	applied, err := history(ctx, conn)
	if err != nil {
		return 0, err
	}
	if err := verify(migrations, applied); err != nil {
		return 0, err
	}
	count := 0
	for _, m := range migrations {
		if _, done := applied[m.Version]; done {
			continue
		}
		if err := apply(ctx, conn, m); err != nil {
			return count, err
		}
		count++
	}
	return count, nil
}

func history(ctx context.Context, conn *pgx.Conn) (map[int]int64, error) {
	rows, err := conn.Query(ctx, readHistory)
	if err != nil {
		return nil, fmt.Errorf("read schema history: %w", err)
	}
	defer rows.Close()
	applied := map[int]int64{}
	for rows.Next() {
		var version int
		var checksum int64
		if err := rows.Scan(&version, &checksum); err != nil {
			return nil, fmt.Errorf("read schema history: %w", err)
		}
		applied[version] = checksum
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("read schema history: %w", err)
	}
	return applied, nil
}

func verify(migrations []Migration, applied map[int]int64) error {
	files := map[int]Migration{}
	for _, m := range migrations {
		files[m.Version] = m
		if checksum, done := applied[m.Version]; done && checksum != m.Checksum {
			return fmt.Errorf("%w: %s changed after it was applied", ErrMigration, m.Name)
		}
	}
	for version := range applied {
		if _, ok := files[version]; !ok {
			return fmt.Errorf("%w: version %d is applied but has no file (a newer build ran here?)", ErrMigration, version)
		}
	}
	return nil
}

func apply(ctx context.Context, conn *pgx.Conn, m Migration) error {
	tx, err := conn.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin %s: %w", m.Name, err)
	}
	defer func() { _ = tx.Rollback(context.WithoutCancel(ctx)) }()
	if _, err := tx.Exec(ctx, m.SQL); err != nil {
		return fmt.Errorf("apply %s: %w", m.Name, err)
	}
	if _, err := tx.Exec(ctx, recordApplied, m.Version, m.Description, m.Checksum); err != nil {
		return fmt.Errorf("record %s: %w", m.Name, err)
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit %s: %w", m.Name, err)
	}
	return nil
}
