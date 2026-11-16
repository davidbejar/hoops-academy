// Package config reads finance-service's settings from the environment (the chart's ConfigMap and Secrets, compose,
// .env), with the defaults the service ships with (Defaults: what the database role check reads).
package config

import (
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// Database is where and as whom the service connects: finance_app for everything it does, finance_migrator only
// to migrate at start (ADR-0006).
type Database struct {
	URL              string // postgres://host:port/db (a jdbc:postgresql:// URL is accepted too)
	AppUser          string
	AppPassword      string
	MigratorUser     string
	MigratorPassword string
}

// AppURL connects as the app role.
func (d Database) AppURL() string { return withUser(d.URL, d.AppUser, d.AppPassword) }

// MigratorURL connects as the migrator.
func (d Database) MigratorURL() string { return withUser(d.URL, d.MigratorUser, d.MigratorPassword) }

func withUser(raw, user, password string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return raw
	}
	u.User = url.UserPassword(user, password)
	return u.String()
}

// OIDC is the realm the tokens come from (ADR-0034).
type OIDC struct {
	AuthServerURL string
	Issuer        string
	Audience      string
}

// Kafka is the roster consumer's broker client (the chart's KAFKA_* of WP71).
type Kafka struct {
	Enabled        bool
	Brokers        []string
	User, Password string // SASL/SCRAM-SHA-256 when KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT
}

// Telemetry switches the OTLP export (the SDK reads OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_TRACES_SAMPLER_ARG and
// OTEL_RESOURCE_ATTRIBUTES itself).
type Telemetry struct{ Enabled bool }

// DuesJob is the daily dues job (decision 98): it ticks every Interval and works on each academy's own date, so a
// period's dues appear within one interval after midnight in the academy's zone.
type DuesJob struct {
	Enabled  bool
	Interval time.Duration
}

// The bounds of the dues job's interval: often enough to follow each academy's midnight, rarely enough to stay cheap.
const (
	minDuesInterval = time.Minute
	maxDuesInterval = 24 * time.Hour
)

// Config is the service's whole configuration.
type Config struct {
	HTTPPort    int
	Database    Database
	OIDC        OIDC
	Kafka       Kafka
	Telemetry   Telemetry
	DuesJob     DuesJob
	CORSOrigins []string
}

// Defaults is the configuration with no environment at all: what the service ships with.
func Defaults() Config {
	return Config{
		HTTPPort: 8085,
		Database: Database{URL: "postgres://localhost:5432/hoops?sslmode=disable", AppUser: "finance_app",
			MigratorUser: "finance_migrator"},
		OIDC:        OIDC{AuthServerURL: "http://localhost:8080/auth/realms/academy", Audience: "finance-service"},
		Kafka:       Kafka{Enabled: true, Brokers: []string{"localhost:19092"}},
		DuesJob:     DuesJob{Enabled: true, Interval: time.Hour},
		CORSOrigins: []string{"http://localhost:5173"},
	}
}

// Load reads getenv over the defaults. A missing password or a malformed value stops the start; errors never repeat
// a value.
func Load(getenv func(string) string) (Config, error) {
	c := Defaults()
	var problems []string
	text := func(key string, into *string) {
		if v := strings.TrimSpace(getenv(key)); v != "" {
			*into = v
		}
	}
	text("FINANCE_DB_USER", &c.Database.AppUser)
	text("FINANCE_MIGRATOR_USER", &c.Database.MigratorUser)
	text("OIDC_AUTH_SERVER_URL", &c.OIDC.AuthServerURL)
	text("OIDC_ISSUER", &c.OIDC.Issuer)
	text("OIDC_AUDIENCE", &c.OIDC.Audience)
	c.Database.AppPassword = getenv("FINANCE_APP_PASSWORD")
	c.Database.MigratorPassword = getenv("FINANCE_MIGRATOR_PASSWORD")
	if c.Database.AppPassword == "" {
		problems = append(problems, "FINANCE_APP_PASSWORD is not set")
	}
	if c.Database.MigratorPassword == "" {
		problems = append(problems, "FINANCE_MIGRATOR_PASSWORD is not set")
	}
	if v := getenv("FINANCE_HTTP_PORT"); v != "" {
		port, err := strconv.Atoi(v)
		if err != nil || port < 1 || port > 65535 {
			problems = append(problems, "FINANCE_HTTP_PORT must be a port number")
		}
		c.HTTPPort = port
	}
	if v := getenv("FINANCE_DB_URL"); v != "" {
		v = strings.Replace(strings.TrimPrefix(v, "jdbc:"), "postgresql://", "postgres://", 1)
		if !strings.HasPrefix(v, "postgres://") {
			problems = append(problems, "FINANCE_DB_URL must be a postgres:// or jdbc:postgresql:// URL")
		}
		c.Database.URL = v
	}
	if v := getenv("HOOPS_CORS_ORIGINS"); v != "" {
		c.CORSOrigins = splitList(v)
	}
	c.Telemetry.Enabled = getenv("OTEL_SDK_DISABLED") == "false"
	problems = append(problems, readKafka(getenv, &c.Kafka)...)
	problems = append(problems, readDuesJob(getenv, &c.DuesJob)...)
	if len(problems) > 0 {
		return c, errors.New("configuration: " + strings.Join(problems, "; "))
	}
	return c, nil
}

func readDuesJob(getenv func(string) string, j *DuesJob) []string {
	if getenv("FINANCE_DUES_JOB_ENABLED") == "false" {
		j.Enabled = false
	}
	v := getenv("FINANCE_DUES_JOB_INTERVAL")
	if v == "" {
		return nil
	}
	interval, err := time.ParseDuration(v)
	if err != nil || interval < minDuesInterval || interval > maxDuesInterval {
		return []string{"FINANCE_DUES_JOB_INTERVAL must be a duration from 1m to 24h"}
	}
	j.Interval = interval
	return nil
}

func readKafka(getenv func(string) string, k *Kafka) []string {
	var problems []string
	if getenv("FINANCE_ROSTER_CONSUMER_ENABLED") == "false" {
		k.Enabled = false
	}
	if v := getenv("KAFKA_BOOTSTRAP_SERVERS"); v != "" {
		k.Brokers = splitList(v)
	}
	switch protocol := getenv("KAFKA_SECURITY_PROTOCOL"); protocol {
	case "", "PLAINTEXT":
	case "SASL_PLAINTEXT":
		k.User, k.Password = getenv("KAFKA_SASL_USERNAME"), getenv("KAFKA_SASL_PASSWORD")
		if k.User == "" || k.Password == "" {
			problems = append(problems, "SASL_PLAINTEXT needs KAFKA_SASL_USERNAME and KAFKA_SASL_PASSWORD")
		}
	default:
		problems = append(problems, fmt.Sprintf("KAFKA_SECURITY_PROTOCOL %q is not supported (PLAINTEXT, SASL_PLAINTEXT)",
			protocol))
	}
	return problems
}

func splitList(v string) []string {
	var out []string
	for _, part := range strings.Split(v, ",") {
		if part = strings.TrimSpace(part); part != "" {
			out = append(out, part)
		}
	}
	return out
}
