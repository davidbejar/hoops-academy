package persistence

import "context"

// QueryRowForTest runs a query in the context's tenant transaction (tests only).
func QueryRowForTest(ctx context.Context, sql string, dest ...any) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	return q.QueryRow(ctx, sql).Scan(dest...)
}

// ExecForTest runs a statement in the context's tenant transaction (tests only).
func ExecForTest(ctx context.Context, sql string) error {
	q, err := txOf(ctx)
	if err != nil {
		return err
	}
	_, err = q.Exec(ctx, sql)
	return err
}
