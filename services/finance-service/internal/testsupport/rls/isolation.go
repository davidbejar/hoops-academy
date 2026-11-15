package rls

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Isolation is the generic data-driven isolation suite (GenericRlsIsolationTest). For one tenant table it inserts,
// as the migrator (the schema owner, subject to the FORCEd policies like everyone), one row for a fresh tenant A and
// one for a fresh tenant B, with the parents their foreign keys need, column values from the catalogue plus
// Overrides. Then, as the app role with A bound to the transaction:
//   - no row of another tenant is visible and A's row is;
//   - an update or delete aimed at B's rows touches 0 rows;
//   - moving A's row to B and inserting a row for B fail with SQLSTATE 42501;
//
// and with no tenant bound any read fails with 42501 (app.current_tenant() raises).
type Isolation struct {
	Migrator, App *pgxpool.Pool
	// Overrides gives column values per table ("schema.table" -> column -> value) for check constraints.
	Overrides map[string]map[string]any
}

const insufficientPrivilege = "42501"

// CheckTable runs the suite on one table and returns its violations.
func (s Isolation) CheckTable(ctx context.Context, table string) ([]string, error) {
	a, b := newUUID(), newUUID()
	rowA, err := s.insertAsMigrator(ctx, table, a)
	if err != nil {
		return nil, err
	}
	rowB, err := s.insertAsMigrator(ctx, table, b)
	if err != nil {
		return nil, err
	}
	_ = rowA
	quoted := quote(table)
	var violations []string
	report := func(format string, args ...any) {
		violations = append(violations, table+": "+fmt.Sprintf(format, args...))
	}

	foreign, err := s.count(ctx, a, "select count(*) from "+quoted+" where tenant_id <> $1", a)
	if err != nil {
		return nil, err
	}
	if foreign != 0 {
		report("tenant %s sees %d rows of other tenants", "A", foreign)
	}
	own, err := s.count(ctx, a, "select count(*) from "+quoted+" where tenant_id = $1", a)
	if err != nil {
		return nil, err
	}
	if own < 1 {
		report("tenant A does not see its own row")
	}
	for _, statement := range []string{
		"update " + quoted + " set tenant_id = tenant_id where tenant_id = $1",
		"delete from " + quoted + " where tenant_id = $1",
	} {
		touched, err := s.exec(ctx, a, statement, b)
		if err != nil && !isInsufficientPrivilege(err) {
			return nil, err
		}
		if touched != 0 {
			report("tenant A changed %d rows of tenant B with %q", touched, firstWord(statement))
		}
	}
	if _, err := s.exec(ctx, a, "update "+quoted+" set tenant_id = $1 where tenant_id = $2", b, a); !isInsufficientPrivilege(err) {
		report("moving a row to tenant B did not fail with 42501 (got %v)", err)
	}
	if err := s.insertAsApp(ctx, table, a, b, rowB); !isInsufficientPrivilege(err) {
		report("inserting a row for tenant B did not fail with 42501 (got %v)", err)
	}
	if err := s.unboundRead(ctx, quoted); !isInsufficientPrivilege(err) {
		report("a read without a bound tenant did not fail with 42501 (got %v)", err)
	}
	return violations, nil
}

func firstWord(statement string) string { return strings.Fields(statement)[0] }

func (s Isolation) count(ctx context.Context, tenant string, sql string, args ...any) (int64, error) {
	var n int64
	err := inTenant(ctx, s.App, tenant, func(tx pgx.Tx) error { return tx.QueryRow(ctx, sql, args...).Scan(&n) })
	return n, err
}

func (s Isolation) exec(ctx context.Context, tenant string, sql string, args ...any) (int64, error) {
	var touched int64
	err := inTenant(ctx, s.App, tenant, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, sql, args...)
		touched = tag.RowsAffected()
		return err
	})
	return touched, err
}

func (s Isolation) unboundRead(ctx context.Context, quoted string) error {
	tx, err := s.App.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	var n int64
	return tx.QueryRow(ctx, "select count(*) from "+quoted).Scan(&n) //nolint:wrapcheck // compared by SQLSTATE
}

func (s Isolation) insertAsApp(ctx context.Context, table, bound, target string, like map[string]any) error {
	cols, err := columnsOf(ctx, s.App, table)
	if err != nil {
		return err
	}
	fks, err := foreignKeysOf(ctx, s.App, table)
	if err != nil {
		return err
	}
	parents := map[string]any{}
	for _, fk := range fks {
		for child := range fk.columns {
			parents[child] = like[child]
		}
	}
	row := s.build(table, cols, target, parents)
	return inTenant(ctx, s.App, bound, func(tx pgx.Tx) error { return insert(ctx, tx, table, row) })
}

// insertAsMigrator inserts a committed row (and its parents) for tenant, bound to that tenant.
func (s Isolation) insertAsMigrator(ctx context.Context, table, tenant string) (map[string]any, error) {
	var row map[string]any
	err := inTenant(ctx, s.Migrator, tenant, func(tx pgx.Tx) error {
		var err error
		row, err = s.insertTree(ctx, tx, table, tenant)
		return err
	})
	if err != nil {
		return nil, fmt.Errorf("fixture of %s: %w", table, err)
	}
	return row, nil
}

func (s Isolation) insertTree(ctx context.Context, tx pgx.Tx, table, tenant string) (map[string]any, error) {
	cols, err := columnsOf(ctx, tx, table)
	if err != nil {
		return nil, err
	}
	fks, err := foreignKeysOf(ctx, tx, table)
	if err != nil {
		return nil, err
	}
	parents := map[string]any{}
	for _, fk := range fks {
		parent, err := s.insertTree(ctx, tx, fk.parent, tenant)
		if err != nil {
			return nil, err
		}
		for child, parentColumn := range fk.columns {
			parents[child] = parent[parentColumn]
		}
	}
	row := s.build(table, cols, tenant, parents)
	return row, insert(ctx, tx, table, row)
}

func (s Isolation) build(table string, cols []column, tenant string, parents map[string]any) map[string]any {
	row := map[string]any{}
	for _, c := range cols {
		switch {
		case c.name == "tenant_id":
			row[c.name] = tenant
		case parents[c.name] != nil:
			row[c.name] = parents[c.name]
		case c.generated || c.nullable:
			continue
		default:
			row[c.name] = sample(c)
		}
	}
	for name, value := range s.Overrides[table] {
		row[name] = value
	}
	return row
}

func sample(c column) any {
	switch c.dataType {
	case "uuid":
		return newUUID()
	case "character":
		return strings.Repeat("X", max(c.length, 1))
	case "integer", "smallint":
		return int32(1)
	case "bigint":
		return int64(1)
	case "boolean":
		return false
	case "timestamp with time zone", "date":
		return time.Now()
	case "jsonb", "json":
		return "{}"
	case "ARRAY":
		return []string{}
	default:
		return "x"
	}
}

func insert(ctx context.Context, tx pgx.Tx, table string, row map[string]any) error {
	names := make([]string, 0, len(row))
	marks := make([]string, 0, len(row))
	values := make([]any, 0, len(row))
	for name, value := range row {
		names = append(names, pgx.Identifier{name}.Sanitize())
		values = append(values, value)
		marks = append(marks, fmt.Sprintf("$%d", len(values)))
	}
	sql := "insert into " + quote(table) + " (" + strings.Join(names, ", ") + ") values (" + strings.Join(marks, ", ") + ")"
	_, err := tx.Exec(ctx, sql, values...)
	return err //nolint:wrapcheck // compared by SQLSTATE
}

type column struct {
	name, dataType      string
	nullable, generated bool
	length              int
}

func columnsOf(ctx context.Context, q Querier, table string) ([]column, error) {
	schema, name, _ := strings.Cut(table, ".")
	rows, err := q.Query(ctx, `
		select column_name, data_type, is_nullable = 'YES',
		       column_default is not null or is_identity = 'YES' or is_generated = 'ALWAYS',
		       coalesce(character_maximum_length, 0)
		  from information_schema.columns where table_schema = $1 and table_name = $2 order by ordinal_position`,
		schema, name)
	if err != nil {
		return nil, fmt.Errorf("columns of %s: %w", table, err)
	}
	cols, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (column, error) {
		var c column
		err := row.Scan(&c.name, &c.dataType, &c.nullable, &c.generated, &c.length)
		return c, err
	})
	if err != nil {
		return nil, fmt.Errorf("columns of %s: %w", table, err)
	}
	return cols, nil
}

type foreignKey struct {
	parent  string
	columns map[string]string // child column -> parent column
}

func foreignKeysOf(ctx context.Context, q Querier, table string) ([]foreignKey, error) {
	schema, name, _ := strings.Cut(table, ".")
	rows, err := q.Query(ctx, `
		select con.conname, pn.nspname || '.' || pc.relname, a.attname, af.attname
		  from pg_constraint con
		  join pg_class c on c.oid = con.conrelid
		  join pg_namespace n on n.oid = c.relnamespace
		  join pg_class pc on pc.oid = con.confrelid
		  join pg_namespace pn on pn.oid = pc.relnamespace
		  cross join lateral unnest(con.conkey, con.confkey) as k(child, parent)
		  join pg_attribute a on a.attrelid = con.conrelid and a.attnum = k.child
		  join pg_attribute af on af.attrelid = con.confrelid and af.attnum = k.parent
		 where con.contype = 'f' and n.nspname = $1 and c.relname = $2
		 order by con.conname`, schema, name)
	if err != nil {
		return nil, fmt.Errorf("foreign keys of %s: %w", table, err)
	}
	defer rows.Close()
	byName := map[string]*foreignKey{}
	var order []string
	for rows.Next() {
		var constraint, parent, child, parentColumn string
		if err := rows.Scan(&constraint, &parent, &child, &parentColumn); err != nil {
			return nil, fmt.Errorf("foreign keys of %s: %w", table, err)
		}
		fk, ok := byName[constraint]
		if !ok {
			fk = &foreignKey{parent: parent, columns: map[string]string{}}
			byName[constraint] = fk
			order = append(order, constraint)
		}
		fk.columns[child] = parentColumn
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("foreign keys of %s: %w", table, err)
	}
	fks := make([]foreignKey, 0, len(order))
	for _, constraint := range order {
		fks = append(fks, *byName[constraint])
	}
	return fks, nil
}

func inTenant(ctx context.Context, pool *pgxpool.Pool, tenant string, fn func(pgx.Tx) error) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	if _, err := tx.Exec(ctx, "select set_config('app.tenant_id', $1, true)", tenant); err != nil {
		return fmt.Errorf("bind tenant: %w", err)
	}
	if err := fn(tx); err != nil {
		return err
	}
	return tx.Commit(ctx) //nolint:wrapcheck // test support
}

func isInsufficientPrivilege(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == insufficientPrivilege
}

func quote(table string) string {
	schema, name, _ := strings.Cut(table, ".")
	return pgx.Identifier{schema, name}.Sanitize()
}

func newUUID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = b[6]&0x0f | 0x40
	b[8] = b[8]&0x3f | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}
