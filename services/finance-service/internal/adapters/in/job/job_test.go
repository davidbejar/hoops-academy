package job_test

import (
	"bytes"
	"context"
	"log/slog"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"hoopsacademy.local/finance/internal/adapters/in/job"
	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/platform/ids"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func TestMain(m *testing.M) { os.Exit(pgtest.Run(m)) }

// The job's day: 16 November 2026, 09:00 UTC (in Jakarta already the afternoon, in Honolulu still the 15th).
var now = time.Date(2026, 11, 16, 9, 0, 0, 0, time.UTC)

type clockAt time.Time

func (c clockAt) Now() time.Time { return time.Time(c) }

func day(m time.Month, d int) time.Time { return time.Date(2026, m, d, 0, 0, 0, 0, time.UTC) }

func randomID() domain.UUID { return ids.V7{}.New() }

func financeOn(pool *pgxpool.Pool, clock application.Clock) *application.Finance {
	return application.NewFinance(persistence.NewPorts(pool, clock, nil))
}

func jobOn(pool *pgxpool.Pool) application.DuesJob {
	return application.NewDuesJob(financeOn(pool, clockAt(now)), persistence.TenantDirectory{Pool: pool},
		persistence.Exclusive{Pool: pool})
}

// academy is an academy of zone with one team (season 1 September 2026 to 30 June 2027) whose plan charges 4500 a month
// from October: Ana since September, Bea since 10 November.
type academy struct {
	tenant domain.TenantID
	plan   domain.FeePlanID
}

func newAcademy(t *testing.T, pool *pgxpool.Pool, status, zone string, autoGenerate bool) academy {
	t.Helper()
	ctx := context.Background()
	tenant, _ := domain.NewTenantID(randomID())
	replica := application.NewReplica(persistence.NewTransactions(pool), persistence.ReplicaStore{})
	at := now.Add(-time.Hour)
	apply := func(topic, kind string, id domain.UUID, fill func(*application.RosterEvent)) {
		at = at.Add(time.Second)
		event := application.RosterEvent{ID: randomID(), Topic: topic, Type: kind, Tenant: tenant, Aggregate: id, OccurredAt: at}
		fill(&event)
		if _, err := replica.Apply(ctx, event); err != nil {
			t.Fatal(err)
		}
	}
	apply("core.tenant", "tenant.changed", tenant.UUID(), func(e *application.RosterEvent) {
		e.TenantData = &application.TenantState{Status: status, Timezone: zone}
	})
	team, season := domain.TeamID(randomID()), domain.SeasonID(randomID())
	apply("core.team", "team.changed", domain.UUID(team), func(e *application.RosterEvent) {
		e.TeamData = &application.TeamState{Season: season, SeasonStart: day(time.September, 1),
			SeasonEnd: time.Date(2027, 6, 30, 0, 0, 0, 0, time.UTC), AgeCategory: domain.AgeCategoryID(randomID())}
	})
	for name, joined := range map[string]time.Time{"Ana": day(time.September, 1), "Bea": day(time.November, 10)} {
		player := domain.PlayerID(randomID())
		apply("core.player", "player.changed", domain.UUID(player), func(e *application.RosterEvent) {
			e.PlayerData = &application.PlayerState{Person: domain.PersonID(randomID()), DisplayName: name, Status: "ACTIVE"}
		})
		apply("core.team-player", "team-player.changed", randomID(), func(e *application.RosterEvent) {
			e.AssignmentData = &application.AssignmentState{Team: team, Player: player, JoinedOn: joined}
		})
	}
	admin := domain.NewMembership("admin", domain.PersonID(randomID()), tenant, []domain.Role{domain.Admin})
	finance := financeOn(pool, clockAt(now))
	if _, err := finance.UpdateSettings(ctx, admin, "EUR"); err != nil {
		t.Fatal(err)
	}
	first := "2026-10"
	plan, err := finance.CreateFeePlan(ctx, admin, application.FeePlanCommand{Input: domain.FeePlanInput{
		Name: "Monthly", Season: season, Team: &team, AmountMinor: 4500, Cadence: "MONTHLY", FirstPeriod: &first,
		AutoGenerate: autoGenerate}})
	if err != nil {
		t.Fatal(err)
	}
	return academy{tenant: tenant, plan: plan.Plan.ID}
}

// count reads a number as finance_app bound to the academy.
func (a academy) count(t *testing.T, pool *pgxpool.Pool, sql string) int {
	t.Helper()
	return pgtest.Value[int](t, pool, a.tenant.String(), sql)
}

const (
	countDues      = "select count(*) from finance.due"
	countGenerated = "select count(*) from finance.audit_event where action = 'dues.generated' and actor_sub = 'system' and actor_person_id is null"
)

// Decision 98: the daily job creates the dues of every started period of each ACTIVE academy's automatic plans, in
// the academy's time zone; with two instances it runs once at a time (a database lock), and a re-run creates nothing.
func TestTheDuesJobRunsOnceAcrossInstancesAndIsIdempotent(t *testing.T) {
	database := pgtest.Start(t)
	ctx := context.Background()
	second, err := pgxpool.New(ctx, database.AppURL) // the second instance's own pool
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(second.Close)
	madrid := newAcademy(t, database.App, "ACTIVE", "Europe/Madrid", true)
	manual := newAcademy(t, database.App, "ACTIVE", "Europe/Madrid", false)
	suspended := newAcademy(t, database.App, "SUSPENDED", "Europe/Madrid", true)
	instanceA, instanceB := jobOn(database.App), jobOn(second)

	held, release := make(chan struct{}), make(chan struct{})
	go func() {
		_, _ = persistence.Exclusive{Pool: database.App}.Run(ctx, application.DuesJobLock, func(context.Context) error {
			close(held)
			<-release
			return nil
		})
	}()
	<-held
	report, ran, err := instanceB.Run(ctx)
	close(release)
	if err != nil || ran || report.Created != 0 || madrid.count(t, database.App, countDues) != 0 {
		t.Fatalf("an instance ran while another held the lock: ran %v %+v %v", ran, report, err)
	}

	var wg sync.WaitGroup
	reports := make([]application.JobReport, 2)
	for i, instance := range []application.DuesJob{instanceA, instanceB} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			report, _, err := instance.Run(ctx)
			if err != nil {
				t.Error(err)
			}
			reports[i] = report
		}()
	}
	wg.Wait()

	// October: Ana; November: Ana and Bea. December has not started.
	if got := madrid.count(t, database.App, countDues); got != 3 {
		t.Errorf("dues of the automatic plan: %d, want 3", got)
	}
	if got := reports[0].Created + reports[1].Created; got != 3 {
		t.Errorf("the two instances created %d dues together (%+v)", got, reports)
	}
	if got := madrid.count(t, database.App, countGenerated); got != 2 {
		t.Errorf("audited generations: %d, want one per period", got)
	}
	if manual.count(t, database.App, countDues) != 0 || suspended.count(t, database.App, countDues) != 0 {
		t.Error("a plan without autoGenerate or a suspended academy got dues")
	}
	again, ran, err := instanceA.Run(ctx)
	if err != nil || !ran || again.Created != 0 || madrid.count(t, database.App, countDues) != 3 ||
		madrid.count(t, database.App, countGenerated) != 2 {
		t.Errorf("a re-run: ran %v %+v %v", ran, again, err)
	}
}

// The academy's own date decides which periods have started: at 20:00 UTC on 30 November it is already 1 December in
// Jakarta (December's dues), still 30 November in Honolulu (none).
func TestTheJobUsesEachAcademysTimeZone(t *testing.T) {
	database := pgtest.Start(t)
	jakarta := newAcademy(t, database.App, "ACTIVE", "Asia/Jakarta", true)
	honolulu := newAcademy(t, database.App, "ACTIVE", "Pacific/Honolulu", true)
	late := time.Date(2026, 11, 30, 20, 0, 0, 0, time.UTC)
	job := application.NewDuesJob(financeOn(database.App, clockAt(late)), persistence.TenantDirectory{Pool: database.App},
		persistence.Exclusive{Pool: database.App})

	if _, _, err := job.Run(context.Background()); err != nil {
		t.Fatal(err)
	}

	december := "select count(*) from finance.due where period = '2026-12'"
	if got := jakarta.count(t, database.App, december); got != 2 {
		t.Errorf("Jakarta's December dues: %d", got)
	}
	if got := honolulu.count(t, database.App, december); got != 0 {
		t.Errorf("Honolulu's December dues: %d", got)
	}
}

func TestTheRunnerRunsTheJobOnItsIntervalAndLogsWhatItDid(t *testing.T) {
	database := pgtest.Start(t)
	newAcademy(t, database.App, "ACTIVE", "UTC", true)
	logs := &bytes.Buffer{}
	var mu sync.Mutex
	runner := job.Runner{Job: jobOn(database.App), Interval: 50 * time.Millisecond,
		Log: slog.New(slog.NewJSONHandler(&lockedWriter{w: logs, mu: &mu}, nil))}
	ctx, stop := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { runner.Run(ctx); close(done) }()

	deadline := time.Now().Add(10 * time.Second)
	for {
		mu.Lock()
		text := logs.String()
		mu.Unlock()
		if strings.Count(text, "dues job") >= 2 {
			if !strings.Contains(text, `"created":3`) {
				t.Errorf("the first run's report is not logged: %s", text)
			}
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("the runner did not run twice: %s", text)
		}
		time.Sleep(20 * time.Millisecond)
	}
	stop()
	<-done
}

type lockedWriter struct {
	w  *bytes.Buffer
	mu *sync.Mutex
}

func (l *lockedWriter) Write(p []byte) (int, error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	return l.w.Write(p)
}
