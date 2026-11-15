// Package pgtest starts the PostgreSQL every database test of finance-service uses: postgres:17 with the
// production bootstrap (infra/db/init: roles, schemas, RLS helpers, passwords), migrated as finance_migrator. Tests
// connect as finance_app (non-owner, no BYPASSRLS) for everything the service does, and as finance_migrator only
// where the Java harness does (fixtures of the generic isolation suite). Never as a superuser (rule 2).
//
// One container per test binary: call Run from TestMain.
package pgtest

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"

	"hoopsacademy.local/finance/db"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
)

// Image is the same PostgreSQL as compose and the Java services' PostgresRlsResource.
const Image = "docker.io/library/postgres:17"

// Database is the started database.
type Database struct {
	// AppURL connects as finance_app, MigratorURL as finance_migrator.
	AppURL, MigratorURL string
	App, Migrator       *pgxpool.Pool
}

var (
	once      sync.Once
	started   *Database
	startErr  error
	container *postgres.PostgresContainer
)

// Run starts nothing by itself: the first Start does. It runs the tests and stops the container afterwards.
func Run(m *testing.M) int {
	code := m.Run()
	if container != nil {
		if started != nil {
			started.App.Close()
			started.Migrator.Close()
		}
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := container.Terminate(ctx); err != nil {
			fmt.Fprintln(os.Stderr, "pgtest: terminate:", err)
		}
	}
	return code
}

// Start returns the database of this test binary, starting and migrating it on first use.
func Start(t testing.TB) *Database {
	t.Helper()
	once.Do(func() { started, startErr = start() })
	if startErr != nil {
		t.Fatalf("pgtest: %v (is Podman running and scripts/env.sh sourced?)", startErr)
	}
	return started
}

// Password of a bootstrap role in tests only (as TestRolePasswords in common-quarkus).
func Password(role string) string { return role + "-test-password" }

var bootstrapRoles = []string{
	"core_migrator", "core_app", "core_platform", "game_migrator", "game_app", "athlete_migrator", "athlete_app",
	"finance_migrator", "finance_app",
}

func start() (*Database, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()
	initDir := filepath.Join(RepoRoot(), "infra", "db", "init")
	env := map[string]string{}
	for _, role := range bootstrapRoles {
		env[strings.ToUpper(role)+"_PASSWORD"] = Password(role)
	}
	ctr, err := postgres.Run(ctx, Image,
		postgres.WithDatabase("hoops"),
		postgres.WithUsername("postgres"),
		postgres.WithPassword(randomSecret()),
		postgres.WithInitScripts(filepath.Join(initDir, "01_roles_schemas.sql"), filepath.Join(initDir, "02_passwords.sh")),
		testcontainers.WithEnv(env),
		postgres.BasicWaitStrategies(),
	)
	container = ctr
	if err != nil {
		return nil, fmt.Errorf("start %s: %w", Image, err)
	}
	host, err := ctr.Host(ctx)
	if err != nil {
		return nil, fmt.Errorf("container host: %w", err)
	}
	port, err := ctr.MappedPort(ctx, "5432/tcp")
	if err != nil {
		return nil, fmt.Errorf("container port: %w", err)
	}
	url := func(role string) string {
		return fmt.Sprintf("postgres://%s:%s@%s:%s/hoops?sslmode=disable", role, Password(role), host, port.Port())
	}
	database := &Database{AppURL: url("finance_app"), MigratorURL: url("finance_migrator")}
	if _, err := persistence.Migrate(ctx, database.MigratorURL, db.Migrations); err != nil {
		return nil, err
	}
	if database.Migrator, err = pgxpool.New(ctx, database.MigratorURL); err != nil {
		return nil, fmt.Errorf("migrator pool: %w", err)
	}
	if database.App, err = pgxpool.New(ctx, database.AppURL); err != nil {
		return nil, fmt.Errorf("app pool: %w", err)
	}
	return database, nil
}

// RepoRoot is the repository's root directory (three levels above the module).
func RepoRoot() string {
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "..", "..", "..", "..", "..")
}

func randomSecret() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}
