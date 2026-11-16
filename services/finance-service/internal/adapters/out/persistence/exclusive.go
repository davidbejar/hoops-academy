package persistence

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/binary"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Exclusive implements application.Exclusive with a transaction-scoped PostgreSQL advisory lock, as common-quarkus'
// TenantScope.runExclusive: `pg_try_advisory_xact_lock` in a lock transaction of its own that binds no tenant and
// reads no table, held while work runs in its own transactions, released when it ends (or when the connection or the
// process dies). It never waits for the lock.
type Exclusive struct{ Pool *pgxpool.Pool }

const tryAdvisoryLock = "select pg_try_advisory_xact_lock($1)"

// Run runs work if no other instance holds lock; false when one does (work did not run).
func (e Exclusive) Run(ctx context.Context, lock string, work func(ctx context.Context) error) (bool, error) {
	tx, err := e.Pool.Begin(ctx)
	if err != nil {
		return false, fmt.Errorf("begin lock %s: %w", lock, err)
	}
	defer func() { _ = tx.Rollback(context.WithoutCancel(ctx)) }()
	var held bool
	if err := tx.QueryRow(ctx, tryAdvisoryLock, AdvisoryKey(lock)).Scan(&held); err != nil {
		return false, fmt.Errorf("lock %s: %w", lock, err)
	}
	if !held {
		return false, nil
	}
	return true, work(ctx)
}

// AdvisoryKey is the 64-bit advisory lock key of a lock name: the first 8 bytes of its SHA-256 (big-endian), the key
// common-quarkus' ExclusiveLocks.advisoryKey computes for the same name.
func AdvisoryKey(name string) int64 {
	sum := sha256.Sum256([]byte(name))
	var key int64
	_ = binary.Read(bytes.NewReader(sum[:8]), binary.BigEndian, &key) // 8 bytes always decode
	return key
}
