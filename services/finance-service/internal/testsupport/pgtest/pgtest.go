// Package pgtest gives every database test of finance-service a PostgreSQL: postgres:17 with the production bootstrap
// (infra/db/init: roles, schemas, RLS helpers, passwords), migrated as finance_migrator. Tests connect as finance_app
// (non-owner, no BYPASSRLS) for everything the service does, and as finance_migrator only where the Java harness does
// (fixtures of the generic isolation suite). Never as a superuser (rule 2).
//
// One database per test binary: call Run from TestMain. When TemplateEnv is set (scripts/check.sh starts one server
// for the whole run with ./internal/testsupport/pgtest/serve), the binary's database is a copy of that server's
// migrated database `hoops` (CREATE DATABASE ... TEMPLATE), so the binaries do not see each other's rows; otherwise
// (go test on one package) the binary starts a container of its own.
package pgtest

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"

	"hoopsacademy.local/finance/db"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
)

// Image is the same PostgreSQL as compose and the Java services' PostgresRlsResource.
const Image = "docker.io/library/postgres:17"

// TemplateEnv names the superuser URL (database postgres) of a running server whose database `hoops` is bootstrapped
// and migrated: the test binaries copy it instead of starting a container each.
const TemplateEnv = "PGTEST_TEMPLATE_URL"

// template is the bootstrapped database: infra/db/init names it, so its copies are made from it.
const template = "hoops"

// Database is the started database.
type Database struct {
	// AppURL connects as finance_app, MigratorURL as finance_migrator.
	AppURL, MigratorURL string
	App, Migrator       *pgxpool.Pool
}

var (
	once     sync.Once
	started  *Database
	startErr error
	release  func()
)

// Run starts nothing by itself: the first Start does. It runs the tests and then drops the binary's database (or
// stops its container).
func Run(m *testing.M) int {
	code := m.Run()
	if started != nil {
		started.App.Close()
		started.Migrator.Close()
	}
	if release != nil {
		release()
	}
	return code
}

// Start returns the database of this test binary, creating it on first use.
func Start(t testing.TB) *Database {
	t.Helper()
	once.Do(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
		defer cancel()
		if admin := os.Getenv(TemplateEnv); admin != "" {
			started, release, startErr = copyTemplate(ctx, admin)
		} else {
			started, release, startErr = ownContainer(ctx)
		}
	})
	if startErr != nil {
		t.Fatalf("pgtest: %v (is Podman running and scripts/env.sh sourced?)", startErr)
	}
	return started
}

// Password of a bootstrap role in tests only (as TestRolePasswords in common-quarkus).
func Password(role string) string { return role + "-test-password" }

// BootstrapRoles are the service roles of infra/db/init/01_roles_schemas.sql, read from its one list (the rows between
// "-- roles: begin" and "-- roles: end", INF-03), so the harness keeps no copy of the names.
func BootstrapRoles() ([]string, error) {
	sql, err := os.ReadFile(filepath.Join(RepoRoot(), "infra", "db", "init", "01_roles_schemas.sql"))
	if err != nil {
		return nil, err
	}
	return rolesOf(string(sql))
}

var (
	roleList = regexp.MustCompile(`(?s)-- roles: begin\n(.*?)-- roles: end\n`)
	roleRow  = regexp.MustCompile(`(?m)^\s*\('([a-z_]+)'`)
)

func rolesOf(sql string) ([]string, error) {
	list := roleList.FindStringSubmatch(sql)
	if list == nil {
		return nil, fmt.Errorf("no '-- roles: begin' / '-- roles: end' list in 01_roles_schemas.sql")
	}
	var roles []string
	for _, row := range roleRow.FindAllStringSubmatch(list[1], -1) {
		roles = append(roles, row[1])
	}
	return roles, nil
}

// Server is a running postgres:17 with database `hoops` bootstrapped and migrated.
type Server struct {
	// AdminURL connects as the container's superuser to the database postgres: only to copy and drop databases.
	AdminURL  string
	container *postgres.PostgresContainer
}

// StartServer starts the container, bootstraps it with infra/db/init and migrates `hoops` as finance_migrator.
func StartServer(ctx context.Context) (*Server, error) {
	initDir := filepath.Join(RepoRoot(), "infra", "db", "init")
	roles, err := BootstrapRoles()
	if err != nil {
		return nil, err
	}
	env := map[string]string{}
	for _, role := range roles {
		env[strings.ToUpper(role)+"_PASSWORD"] = Password(role)
	}
	superuser := randomHex(16)
	ctr, err := postgres.Run(ctx, Image,
		postgres.WithDatabase(template),
		postgres.WithUsername("postgres"),
		postgres.WithPassword(superuser),
		postgres.WithInitScripts(filepath.Join(initDir, "01_roles_schemas.sql"), filepath.Join(initDir, "02_passwords.sh")),
		testcontainers.WithEnv(env),
		postgres.BasicWaitStrategies(),
	)
	server := &Server{container: ctr}
	if err != nil {
		return server, fmt.Errorf("start %s: %w", Image, err)
	}
	host, err := ctr.Host(ctx)
	if err != nil {
		return server, fmt.Errorf("container host: %w", err)
	}
	port, err := ctr.MappedPort(ctx, "5432/tcp")
	if err != nil {
		return server, fmt.Errorf("container port: %w", err)
	}
	server.AdminURL = (&url.URL{Scheme: "postgres", User: url.UserPassword("postgres", superuser),
		Host: host + ":" + port.Port(), Path: "/postgres", RawQuery: "sslmode=disable"}).String()
	if _, err := persistence.Migrate(ctx, roleURL(server.AdminURL, "finance_migrator", template), db.Migrations); err != nil {
		return server, err
	}
	return server, nil
}

// Stop terminates the container.
func (s *Server) Stop() {
	if s.container == nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := s.container.Terminate(ctx); err != nil {
		fmt.Fprintln(os.Stderr, "pgtest: terminate:", err)
	}
}

func ownContainer(ctx context.Context) (*Database, func(), error) {
	server, err := StartServer(ctx)
	if err != nil {
		return nil, server.Stop, err
	}
	database, err := open(ctx, server.AdminURL, template)
	return database, server.Stop, err
}

// copyTemplate creates the binary's own database as a copy of the server's `hoops`, with hoops' database privileges
// (CREATE DATABASE does not copy them: PUBLIC would get CONNECT and TEMPORARY).
func copyTemplate(ctx context.Context, admin string) (*Database, func(), error) {
	name := "finance_test_" + randomHex(8)
	conn, err := pgx.Connect(ctx, admin)
	if err != nil {
		return nil, nil, fmt.Errorf("connect to the test server: %w", err)
	}
	defer func() { _ = conn.Close(ctx) }()
	ident := pgx.Identifier{name}.Sanitize()
	if _, err := conn.Exec(ctx, "create database "+ident+" template "+template); err != nil {
		return nil, nil, fmt.Errorf("copy %s: %w", template, err)
	}
	drop := func() {
		ctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 30*time.Second)
		defer cancel()
		if conn, err := pgx.Connect(ctx, admin); err == nil {
			_, _ = conn.Exec(ctx, "drop database if exists "+ident+" with (force)")
			_ = conn.Close(ctx)
		}
	}
	grants, err := conn.Query(ctx, `select a.privilege_type, r.rolname from pg_database d
		cross join aclexplode(d.datacl) a join pg_roles r on r.oid = a.grantee
		where d.datname = $1 and a.grantee <> d.datdba`, template)
	if err != nil {
		return nil, drop, fmt.Errorf("privileges of %s: %w", template, err)
	}
	statements := []string{"revoke all on database " + ident + " from public"}
	var privilege, role string
	_, err = pgx.ForEachRow(grants, []any{&privilege, &role}, func() error {
		statements = append(statements, fmt.Sprintf("grant %s on database %s to %s", privilege, ident,
			pgx.Identifier{role}.Sanitize()))
		return nil
	})
	if err != nil {
		return nil, drop, fmt.Errorf("privileges of %s: %w", template, err)
	}
	for _, statement := range statements {
		if _, err := conn.Exec(ctx, statement); err != nil {
			return nil, drop, fmt.Errorf("%s: %w", statement, err)
		}
	}
	database, err := open(ctx, admin, name)
	return database, drop, err
}

// open connects finance_app and finance_migrator to database (migrated: Migrate only checks the applied versions).
func open(ctx context.Context, admin, database string) (*Database, error) {
	d := &Database{AppURL: roleURL(admin, "finance_app", database), MigratorURL: roleURL(admin, "finance_migrator", database)}
	if _, err := persistence.Migrate(ctx, d.MigratorURL, db.Migrations); err != nil {
		return nil, err
	}
	var err error
	if d.Migrator, err = pgxpool.New(ctx, d.MigratorURL); err != nil {
		return nil, fmt.Errorf("migrator pool: %w", err)
	}
	if d.App, err = pgxpool.New(ctx, d.AppURL); err != nil {
		d.Migrator.Close()
		return nil, fmt.Errorf("app pool: %w", err)
	}
	return d, nil
}

// roleURL is admin's server with role's test password and database.
func roleURL(admin, role, database string) string {
	u, _ := url.Parse(admin) // built by StartServer or set by scripts/check.sh from it
	u.User = url.UserPassword(role, Password(role))
	u.Path = "/" + database
	return u.String()
}

// RepoRoot is the repository's root directory (three levels above the module).
func RepoRoot() string {
	_, file, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(file), "..", "..", "..", "..", "..")
}

func randomHex(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}
