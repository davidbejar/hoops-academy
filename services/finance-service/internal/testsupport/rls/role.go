package rls

import (
	"context"
	"fmt"
	"sort"
)

// CheckDatabaseRole is the counterpart of common-quarkus' DatabaseRoleCheck: the role a service connects as must be
// bound by row-level security, i.e. not a superuser, not BYPASSRLS, not owner (nor member of the owner) of any table,
// view or sequence outside the system catalogues, and without CREATE on the database or on any schema.
func CheckDatabaseRole(ctx context.Context, q Querier, role string) ([]string, error) {
	var exists, super, bypass, createDB bool
	err := q.QueryRow(ctx, `
		select count(*) = 1, coalesce(bool_or(rolsuper), false), coalesce(bool_or(rolbypassrls), false),
		       coalesce(bool_or(has_database_privilege(rolname, current_database(), 'CREATE')), false)
		  from pg_roles where rolname = $1`, role).Scan(&exists, &super, &bypass, &createDB)
	if err != nil {
		return nil, fmt.Errorf("role %s: %w", role, err)
	}
	if !exists {
		return []string{role + ": no such role"}, nil
	}
	var violations []string
	if super {
		violations = append(violations, role+": is a superuser")
	}
	if bypass {
		violations = append(violations, role+": has BYPASSRLS")
	}
	if createDB {
		violations = append(violations, role+": may CREATE in the database")
	}
	owned, err := texts(ctx, q, `
		select n.nspname || '.' || c.relname
		  from pg_class c join pg_namespace n on n.oid = c.relnamespace
		 where c.relkind in ('r', 'p', 'v', 'm', 'S')
		   and n.nspname not in ('pg_catalog', 'information_schema') and n.nspname not like 'pg_toast%'
		   and pg_has_role($1, c.relowner, 'MEMBER')`, role)
	if err != nil {
		return nil, err
	}
	for _, name := range owned {
		violations = append(violations, role+": owns (or is a member of the owner of) "+name)
	}
	schemas, err := texts(ctx, q, `
		select nspname from pg_namespace
		 where nspname not like 'pg\_%' and nspname <> 'information_schema' and has_schema_privilege($1, oid, 'CREATE')`,
		role)
	if err != nil {
		return nil, err
	}
	for _, name := range schemas {
		violations = append(violations, role+": may CREATE in schema "+name)
	}
	sort.Strings(violations)
	return violations, nil
}

func texts(ctx context.Context, q Querier, sql string, args ...any) ([]string, error) {
	rows, err := q.Query(ctx, sql, args...)
	if err != nil {
		return nil, fmt.Errorf("role check: %w", err)
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, fmt.Errorf("role check: %w", err)
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("role check: %w", err)
	}
	return out, nil
}
