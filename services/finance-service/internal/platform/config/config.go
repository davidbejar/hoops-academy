// Package config reads finance-service's settings from the environment, with the defaults the service ships with.
package config

// Database is where and as whom the service connects.
type Database struct {
	URL          string
	AppUser      string
	MigratorUser string
}

// Config is the service's whole configuration.
type Config struct {
	Database Database
}

// Defaults is the configuration with no environment at all: what the service ships with.
func Defaults() Config {
	return Config{}
}
