// Command serve starts the one PostgreSQL of a test run (scripts/check.sh): it bootstraps and migrates `hoops`, writes
// the superuser URL (pgtest.TemplateEnv) to the file named by its argument (mode 0600) and keeps the container until
// it is stopped (SIGTERM or SIGINT) or its parent process ends; the test binaries copy `hoops` for themselves.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func main() { os.Exit(run()) }

func run() int {
	if len(os.Args) != 2 {
		slog.Error("usage: serve <file for the server URL>")
		return 2
	}
	parent := os.Getppid()
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, os.Interrupt)
	defer stop()
	server, err := pgtest.StartServer(ctx)
	defer server.Stop()
	if err != nil {
		slog.Error("pgtest server", slog.String("error", err.Error()))
		return 1
	}
	if err := os.WriteFile(os.Args[1], []byte(server.AdminURL), 0o600); err != nil {
		slog.Error("pgtest server URL", slog.String("error", err.Error()))
		return 1
	}
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return 0
		case <-ticker.C:
			if os.Getppid() != parent { // the script ended without stopping the server
				return 0
			}
		}
	}
}
