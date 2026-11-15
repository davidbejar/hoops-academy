package persistence_test

import (
	"context"
	"os"
	"slices"
	"strings"
	"testing"

	"hoopsacademy.local/finance/internal/platform/config"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
	"hoopsacademy.local/finance/internal/testsupport/rls"
)

func TestMain(m *testing.M) { os.Exit(pgtest.Run(m)) }

const schema = "finance"

// The tables of schema finance without tenant_id, each with its reason (RlsSchemaMetaTest.globalTables()).
var globalTables = map[string]string{
	"finance.schema_history": "the migration runner's history, written by finance_migrator only; finance_app has no grant",
	"finance.parked_event":   "an invalid event may not name a tenant (ADR-0037 §4); finance_app may only insert",
	"finance.replica_tenant": "tenant ids only, no tenant content, so housekeeping can enter each tenant; read + insert",
}

// Column values the catalogue cannot guess (check constraints), per table (GenericRlsIsolationTest.fixtureOverrides()).
var fixtureOverrides = map[string]map[string]any{
	"finance.fee_plan": {"cadence": "SEASON", "team_id": "6f1c8a52-0d8e-4f5e-9a51-2a8f0c3b7d11"},
	"finance.due":      {"status": "OPEN", "period": "SEASON"},
	"finance.payment":  {"method": "CASH"},
}

func TestEveryTenantTableIsForcedUnderRowLevelSecurity(t *testing.T) {
	database := pgtest.Start(t)

	violations, err := rls.InspectSchema(context.Background(), database.App, schema, globalTables)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range violations {
		t.Error(v)
	}
}

func TestTheSchemaInspectionFindsPlantedViolations(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()
	tx, err := database.Migrator.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	for _, ddl := range []string{
		"create table finance.planted_no_rls (tenant_id uuid not null)",
		"create table finance.planted_not_forced (tenant_id uuid not null)",
		"alter table finance.planted_not_forced enable row level security",
		"create policy p on finance.planted_not_forced using (tenant_id = app.current_tenant())",
		"create table finance.planted_open (tenant_id uuid not null)",
		"select app.enable_tenant_rls('finance.planted_open')",
		"create policy everyone on finance.planted_open using (true)",
		"create table finance.planted_nullable (tenant_id uuid)",
		"select app.enable_tenant_rls('finance.planted_nullable')",
		"create table finance.planted_global (id uuid)",
	} {
		if _, err := tx.Exec(ctx, ddl); err != nil {
			t.Fatalf("%s: %v", ddl, err)
		}
	}

	violations, err := rls.InspectSchema(ctx, tx, schema, globalTables)
	if err != nil {
		t.Fatal(err)
	}

	for _, want := range []string{
		"finance.planted_global: no tenant_id and not declared global (with a reason)",
		"finance.planted_no_rls: row level security not enabled",
		"finance.planted_no_rls: row level security not forced",
		"finance.planted_no_rls: no permissive policy on app.current_tenant()",
		"finance.planted_not_forced: row level security not forced",
		"finance.planted_not_forced: policy p writes without app.current_tenant()",
		"finance.planted_nullable: tenant_id must be uuid not null",
		"finance.planted_open: policy everyone reads without app.current_tenant()",
		"finance.planted_open: policy everyone writes without app.current_tenant()",
	} {
		if !slices.Contains(violations, want) {
			t.Errorf("not reported: %s", want)
		}
	}
	if len(violations) != 9 {
		t.Errorf("expected exactly the 9 planted violations, got:\n%s", strings.Join(violations, "\n"))
	}
}

func TestNoTenantReadsOrChangesAnotherTenantsRows(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()
	tables, err := rls.TenantTables(ctx, database.App, schema)
	if err != nil {
		t.Fatal(err)
	}
	if len(tables) < 8 {
		t.Fatalf("expected the tenant tables of V1-V5, found %v", tables)
	}
	suite := rls.Isolation{Migrator: database.Migrator, App: database.App, Overrides: fixtureOverrides}
	for _, table := range tables {
		t.Run(table, func(t *testing.T) {
			violations, err := suite.CheckTable(ctx, table)
			if err != nil {
				t.Fatal(err)
			}
			for _, v := range violations {
				t.Error(v)
			}
		})
	}
}

func TestTheIsolationSuiteFailsOnAPlantedLeak(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()
	for _, ddl := range []string{
		"create table finance.planted_leak (tenant_id uuid not null, id uuid primary key)",
		"select app.enable_tenant_rls('finance.planted_leak')",
		"create policy everyone on finance.planted_leak using (true) with check (true)",
	} {
		if _, err := database.Migrator.Exec(ctx, ddl); err != nil {
			t.Fatalf("%s: %v", ddl, err)
		}
	}
	t.Cleanup(func() { _, _ = database.Migrator.Exec(ctx, "drop table finance.planted_leak") })
	suite := rls.Isolation{Migrator: database.Migrator, App: database.App}

	violations, err := suite.CheckTable(ctx, "finance.planted_leak")
	if err != nil {
		t.Fatal(err)
	}

	joined := strings.Join(violations, "\n")
	for _, want := range []string{
		"sees 1 rows of other tenants",
		`changed 1 rows of tenant B with "update"`,
		`changed 1 rows of tenant B with "delete"`,
		"moving a row to tenant B did not fail",
		"inserting a row for tenant B did not fail",
	} {
		if !strings.Contains(joined, want) {
			t.Errorf("planted leak not reported: %q\nreported:\n%s", want, joined)
		}
	}
}

func TestTheShippedDatabaseRoleIsBoundByRowLevelSecurity(t *testing.T) {
	database := pgtest.Start(t)
	shipped := config.Defaults().Database

	if shipped.AppUser != "finance_app" || shipped.AppUser == shipped.MigratorUser {
		t.Fatalf("the service must ship with finance_app, distinct from the migrator: %+v", shipped)
	}
	violations, err := rls.CheckDatabaseRole(context.Background(), database.App, shipped.AppUser)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range violations {
		t.Error(v)
	}
}

func TestTheDatabaseRoleCheckRefusesOwnersAndSuperusers(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()

	migrator, err := rls.CheckDatabaseRole(ctx, database.App, "finance_migrator")
	if err != nil {
		t.Fatal(err)
	}
	superuser, err := rls.CheckDatabaseRole(ctx, database.App, "postgres")
	if err != nil {
		t.Fatal(err)
	}

	if !slices.Contains(migrator, "finance_migrator: owns (or is a member of the owner of) finance.fee_plan") ||
		!slices.Contains(migrator, "finance_migrator: may CREATE in schema finance") {
		t.Errorf("the owner passed the role check: %v", migrator)
	}
	if !slices.Contains(superuser, "postgres: is a superuser") || !slices.Contains(superuser, "postgres: has BYPASSRLS") {
		t.Errorf("the superuser passed the role check: %v", superuser)
	}
}

func TestTheAppRoleCannotReadTheGlobalTablesItMustNot(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()
	for _, table := range []string{"finance.schema_history", "finance.parked_event"} {
		var allowed bool
		if err := database.App.QueryRow(ctx, "select has_table_privilege('finance_app', $1, 'SELECT')", table).
			Scan(&allowed); err != nil {
			t.Fatal(err)
		}
		if allowed {
			t.Errorf("finance_app may read %s", table)
		}
	}
}
