// Package rls holds the Go counterparts of common-quarkus' RlsSchemaMetaTest, GenericRlsIsolationTest and
// DatabaseRoleCheck (ADR-0055, rule 2). Each check returns its violations as text, so a test can both fail on them
// for the real schema and prove, on planted tables, that it finds them.
package rls

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
)

// Querier is what the checks read the catalogue through (a pool, a connection or a transaction).
type Querier interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

const tenantFunction = "current_tenant()"

type tableInfo struct {
	name            string
	rowSecurity     bool
	forced          bool
	hasTenant       bool
	tenantType      string
	tenantNullable  bool
	policies        []policy
	permissiveCount int
}

type policy struct {
	name, command, using, check string
	permissive                  bool
}

// InspectSchema is the schema meta test (RlsSchemaMetaTest): every table of schema with a tenant_id column has a
// uuid NOT NULL tenant_id, row-level security enabled AND forced, at least one policy, and every permissive policy
// restricts both reads (USING) and writes (WITH CHECK, or USING for a FOR ALL policy without one) to
// app.current_tenant(); a table without tenant_id must be listed in globals ("schema.table" -> reason).
func InspectSchema(ctx context.Context, q Querier, schema string, globals map[string]string) ([]string, error) {
	tables, err := tablesOf(ctx, q, schema)
	if err != nil {
		return nil, err
	}
	var violations []string
	for _, table := range tables {
		qualified := schema + "." + table.name
		if !table.hasTenant {
			if strings.TrimSpace(globals[qualified]) == "" {
				violations = append(violations, qualified+": no tenant_id and not declared global (with a reason)")
			}
			continue
		}
		violations = append(violations, tenantTableViolations(qualified, table)...)
	}
	for name := range globals {
		if !strings.HasPrefix(name, schema+".") || !contains(tables, strings.TrimPrefix(name, schema+".")) {
			violations = append(violations, name+": declared global but no such table")
		}
	}
	sort.Strings(violations)
	return violations, nil
}

func contains(tables []tableInfo, name string) bool {
	for _, t := range tables {
		if t.name == name {
			return true
		}
	}
	return false
}

func tenantTableViolations(qualified string, table tableInfo) []string {
	var out []string
	if table.tenantType != "uuid" || table.tenantNullable {
		out = append(out, qualified+": tenant_id must be uuid not null")
	}
	if !table.rowSecurity {
		out = append(out, qualified+": row level security not enabled")
	}
	if !table.forced {
		out = append(out, qualified+": row level security not forced")
	}
	if table.permissiveCount == 0 {
		out = append(out, qualified+": no permissive policy on app.current_tenant()")
	}
	for _, p := range table.policies {
		if !p.permissive {
			continue
		}
		check := p.check
		if check == "" && p.command == "ALL" {
			check = p.using
		}
		if needsUsing(p.command) && !strings.Contains(p.using, tenantFunction) {
			out = append(out, fmt.Sprintf("%s: policy %s reads without app.current_tenant()", qualified, p.name))
		}
		if needsCheck(p.command) && !strings.Contains(check, tenantFunction) {
			out = append(out, fmt.Sprintf("%s: policy %s writes without app.current_tenant()", qualified, p.name))
		}
	}
	return out
}

func needsUsing(command string) bool { return command != "INSERT" }
func needsCheck(command string) bool { return command == "ALL" || command == "INSERT" || command == "UPDATE" }

func tablesOf(ctx context.Context, q Querier, schema string) ([]tableInfo, error) {
	rows, err := q.Query(ctx, `
		select c.relname, c.relrowsecurity, c.relforcerowsecurity,
		       coalesce(col.data_type, ''), coalesce(col.is_nullable = 'YES', false), col.column_name is not null
		  from pg_class c
		  join pg_namespace n on n.oid = c.relnamespace
		  left join information_schema.columns col
		    on col.table_schema = n.nspname and col.table_name = c.relname and col.column_name = 'tenant_id'
		 where n.nspname = $1 and c.relkind in ('r', 'p')
		 order by c.relname`, schema)
	if err != nil {
		return nil, fmt.Errorf("tables of %s: %w", schema, err)
	}
	tables, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (tableInfo, error) {
		var t tableInfo
		err := row.Scan(&t.name, &t.rowSecurity, &t.forced, &t.tenantType, &t.tenantNullable, &t.hasTenant)
		return t, err
	})
	if err != nil {
		return nil, fmt.Errorf("tables of %s: %w", schema, err)
	}
	for i := range tables {
		if tables[i].policies, err = policiesOf(ctx, q, schema, tables[i].name); err != nil {
			return nil, err
		}
		for _, p := range tables[i].policies {
			if p.permissive {
				tables[i].permissiveCount++
			}
		}
	}
	return tables, nil
}

func policiesOf(ctx context.Context, q Querier, schema, table string) ([]policy, error) {
	rows, err := q.Query(ctx, `
		select policyname, cmd, coalesce(qual, ''), coalesce(with_check, ''), permissive = 'PERMISSIVE'
		  from pg_policies where schemaname = $1 and tablename = $2 order by policyname`, schema, table)
	if err != nil {
		return nil, fmt.Errorf("policies of %s.%s: %w", schema, table, err)
	}
	policies, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (policy, error) {
		var p policy
		err := row.Scan(&p.name, &p.command, &p.using, &p.check, &p.permissive)
		return p, err
	})
	if err != nil {
		return nil, fmt.Errorf("policies of %s.%s: %w", schema, table, err)
	}
	return policies, nil
}

// TenantTables lists the tables of schema that carry a tenant_id column.
func TenantTables(ctx context.Context, q Querier, schema string) ([]string, error) {
	tables, err := tablesOf(ctx, q, schema)
	if err != nil {
		return nil, err
	}
	var names []string
	for _, t := range tables {
		if t.hasTenant {
			names = append(names, schema+"."+t.name)
		}
	}
	return names, nil
}
