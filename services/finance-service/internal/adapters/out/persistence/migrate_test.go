package persistence_test

import (
	"context"
	"testing"
	"testing/fstest"

	"hoopsacademy.local/finance/db"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func TestTheMigrationsAreNumberedOneConcernPerFile(t *testing.T) {
	migrations, err := persistence.LoadMigrations(db.Migrations)
	if err != nil {
		t.Fatal(err)
	}
	if len(migrations) < 5 || migrations[0].Version != 1 {
		t.Fatalf("expected V1..V5 at least, got %+v", migrations)
	}
	for i, m := range migrations {
		if m.Version > 19 {
			t.Errorf("V%d: WP118 and WP119 own V1-V19 only (V20-V29 WP123)", m.Version)
		}
		if i > 0 && m.Version <= migrations[i-1].Version {
			t.Errorf("not in order: %s after %s", m.Name, migrations[i-1].Name)
		}
	}
}

func TestMigrationFileNamesMustFollowTheConvention(t *testing.T) {
	for _, name := range []string{"V1_settings.sql", "v1__settings.sql", "V1__Settings.sql", "V01__a.sql", "V1__a.txt"} {
		fsys := fstest.MapFS{"migration/" + name: {Data: []byte("select 1;")}}
		if _, err := persistence.LoadMigrations(fsys); err == nil {
			t.Errorf("%s was accepted", name)
		}
	}
	twice := fstest.MapFS{
		"migration/V1__a.sql": {Data: []byte("select 1;")},
		"migration/V1__b.sql": {Data: []byte("select 1;")},
	}
	if _, err := persistence.LoadMigrations(twice); err == nil {
		t.Error("two files with version 1 were accepted")
	}
}

func TestMigratingAgainAppliesNothingAndAChangedFileIsRefused(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()

	applied, err := persistence.Migrate(ctx, database.MigratorURL, db.Migrations)
	if err != nil {
		t.Fatal(err)
	}
	if applied != 0 {
		t.Errorf("a second run applied %d migrations", applied)
	}

	changed := fstest.MapFS{"migration/V1__settings.sql": {Data: []byte("select 'edited';")}}
	if _, err := persistence.Migrate(ctx, database.MigratorURL, changed); err == nil {
		t.Error("a changed applied migration was accepted")
	}
}
