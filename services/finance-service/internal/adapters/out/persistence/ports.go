package persistence

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/application"
	uuidv7 "hoopsacademy.local/finance/internal/platform/ids"
)

// NewPorts wires every port of the use cases to the stores on pool (connected as finance_app), with clock and the
// audit trail logged to log (nil: the database only). The service and the tests build their ports here, so they
// cannot drift.
func NewPorts(pool *pgxpool.Pool, clock application.Clock, log *slog.Logger) application.Ports {
	//nolint:govet // unkeyed on purpose: a port added to application.Ports does not compile until it is wired here
	return application.Ports{
		clock, uuidv7.V7{}, NewTransactions(pool), SettingsStore{}, FeePlanStore{}, AuditLog{IDs: uuidv7.V7{}, Log: log},
		MembershipStore{}, RosterStore{}, DueStore{}, PaymentStore{}, ExpenseStore{},
	}
}
