package config

import (
	"strings"
	"testing"
)

func env(values map[string]string) func(string) string {
	return func(key string) string { return values[key] }
}

var secrets = map[string]string{"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m"}

func TestTheDefaultsAreTheLocalDevelopmentSetup(t *testing.T) {
	c, err := Load(env(secrets))
	if err != nil {
		t.Fatal(err)
	}
	if c.HTTPPort != 8085 || c.Database.AppUser != "finance_app" || c.Database.MigratorUser != "finance_migrator" ||
		c.Database.URL != "postgres://localhost:5432/hoops?sslmode=disable" || c.OIDC.Audience != "finance-service" ||
		c.OIDC.AuthServerURL != "http://localhost:8080/auth/realms/academy" || !c.Kafka.Enabled ||
		c.Kafka.Brokers[0] != "localhost:19092" || c.Kafka.User != "" || c.Telemetry.Enabled ||
		c.CORSOrigins[0] != "http://localhost:5173" {
		t.Errorf("defaults %+v", c)
	}
}

func TestTheChartsEnvironmentIsRead(t *testing.T) {
	values := map[string]string{
		"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m", "FINANCE_HTTP_PORT": "9000",
		"FINANCE_DB_URL":       "jdbc:postgresql://hoops-db-rw:5432/hoops",
		"OIDC_AUTH_SERVER_URL": "http://keycloak:8080/auth/realms/academy", "OIDC_ISSUER": "http://public/x",
		"KAFKA_BOOTSTRAP_SERVERS": "redpanda.hoops.svc.cluster.local:9092", "KAFKA_SECURITY_PROTOCOL": "SASL_PLAINTEXT",
		"KAFKA_SASL_USERNAME": "finance-service", "KAFKA_SASL_PASSWORD": "k", "OTEL_SDK_DISABLED": "false",
		"HOOPS_CORS_ORIGINS": "http://a, http://b", "FINANCE_ROSTER_CONSUMER_ENABLED": "false",
	}
	c, err := Load(env(values))
	if err != nil {
		t.Fatal(err)
	}
	if c.HTTPPort != 9000 || c.Database.URL != "postgres://hoops-db-rw:5432/hoops" || c.OIDC.Issuer != "http://public/x" ||
		c.Kafka.User != "finance-service" || c.Kafka.Password != "k" || c.Kafka.Enabled || !c.Telemetry.Enabled ||
		strings.Join(c.CORSOrigins, "|") != "http://a|http://b" {
		t.Errorf("read %+v", c)
	}
	if c.Database.AppURL() != "postgres://finance_app:a@hoops-db-rw:5432/hoops" ||
		c.Database.MigratorURL() != "postgres://finance_migrator:m@hoops-db-rw:5432/hoops" {
		t.Errorf("urls %s %s", c.Database.AppURL(), c.Database.MigratorURL())
	}
}

func TestMissingSecretsAndBadValuesStopTheStart(t *testing.T) {
	for name, values := range map[string]map[string]string{
		"no app password":      {"FINANCE_MIGRATOR_PASSWORD": "m"},
		"no migrator password": {"FINANCE_APP_PASSWORD": "a"},
		"bad port":             {"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m", "FINANCE_HTTP_PORT": "x"},
		"sasl without user": {"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m",
			"KAFKA_SECURITY_PROTOCOL": "SASL_PLAINTEXT"},
		"unknown protocol": {"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m",
			"KAFKA_SECURITY_PROTOCOL": "SSL"},
		"bad url": {"FINANCE_APP_PASSWORD": "a", "FINANCE_MIGRATOR_PASSWORD": "m", "FINANCE_DB_URL": "mysql://x"},
	} {
		if _, err := Load(env(values)); err == nil {
			t.Errorf("%s: accepted", name)
		}
	}
	values := map[string]string{"FINANCE_APP_PASSWORD": "secret-app", "FINANCE_MIGRATOR_PASSWORD": "m",
		"FINANCE_DB_URL": "jdbc:mysql://x"}
	if _, err := Load(env(values)); err != nil && strings.Contains(err.Error(), "secret-app") {
		t.Error("an error repeats a password")
	}
}

// The dues job (decision 98) runs every hour by default; it can be switched off or run more or less often (at least
// every minute, at most every day: the academies' dates must be checked daily).
func TestTheDuesJobRunsHourlyUnlessConfigured(t *testing.T) {
	c, err := Load(env(secrets))
	if err != nil || !c.DuesJob.Enabled || c.DuesJob.Interval.String() != "1h0m0s" {
		t.Errorf("default %+v %v", c.DuesJob, err)
	}
	values := map[string]string{"FINANCE_DUES_JOB_ENABLED": "false", "FINANCE_DUES_JOB_INTERVAL": "15m"}
	for k, v := range secrets {
		values[k] = v
	}
	c, err = Load(env(values))
	if err != nil || c.DuesJob.Enabled || c.DuesJob.Interval.String() != "15m0s" {
		t.Errorf("configured %+v %v", c.DuesJob, err)
	}
	for _, bad := range []string{"soon", "30s", "25h"} {
		values["FINANCE_DUES_JOB_INTERVAL"] = bad
		if _, err := Load(env(values)); err == nil || !strings.Contains(err.Error(), "FINANCE_DUES_JOB_INTERVAL") {
			t.Errorf("%s: %v", bad, err)
		}
	}
}
