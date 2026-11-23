package events

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go/modules/redpanda"
	"github.com/twmb/franz-go/pkg/kadm"
	"github.com/twmb/franz-go/pkg/kgo"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
	"hoopsacademy.local/finance/internal/domain"
	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

func TestMain(m *testing.M) { os.Exit(pgtest.Run(m)) }

// The same Redpanda as compose and the chart (events.redpanda.image).
const redpandaImage = "docker.io/redpandadata/redpanda:v26.3.1@sha256:260532f70fd840bf2159106bd4ef900f199c1f5ca2a23cb362642320513b90f5"

// core's events reach the replica through a real broker: the academy and its admin resolve afterwards, an invalid
// record is parked and does not block the ones after it, and the consumer's offsets are committed.
func TestTheConsumerFillsTheReplicaFromCoresTopics(t *testing.T) {
	ctx := context.Background()
	database := pgtest.Start(t)
	broker, err := redpanda.Run(ctx, redpandaImage)
	if err != nil {
		t.Fatalf("redpanda: %v", err)
	}
	t.Cleanup(func() { _ = broker.Terminate(context.Background()) })
	seed, err := broker.KafkaSeedBroker(ctx)
	if err != nil {
		t.Fatal(err)
	}
	client, err := kgo.NewClient(kgo.SeedBrokers(seed))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(client.Close)
	if _, err := kadm.NewClient(client).CreateTopics(ctx, 1, 1, nil, Topics...); err != nil {
		t.Fatal(err)
	}
	tenantValue := examples(t, "core.tenant")[0]
	personValue := examples(t, "core.person")[0]
	produce := func(topic string, key, value []byte) {
		if err := client.ProduceSync(ctx, &kgo.Record{Topic: topic, Key: key, Value: value}).FirstErr(); err != nil {
			t.Fatal(err)
		}
	}
	produce("core.person", []byte("wrong:key"), personValue) // parked, not blocking
	produce("core.tenant", keyOf(t, tenantValue), tenantValue)
	produce("core.person", keyOf(t, personValue), personValue)
	produce("core.person", keyOf(t, personValue), nil) // a tombstone: skipped

	tx := persistence.NewTransactions(database.App)
	metrics := NewMetrics()
	consumer, err := NewConsumer(Config{Brokers: []string{seed}, Group: "finance-service.roster"},
		NewDecoder(), application.NewReplica(tx, persistence.ReplicaStore{}), persistence.ParkedEvents{Pool: database.App},
		metrics, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	run, stop := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() { done <- consumer.Run(run) }()
	defer func() {
		stop()
		if err := <-done; err != nil {
			t.Errorf("the consumer stopped with %v", err)
		}
	}()

	var envelope struct {
		TenantID string
		Payload  struct{ Subject string }
	}
	_ = json.Unmarshal(personValue, &envelope)
	tenant, _ := domain.ParseTenantID(envelope.TenantID)
	deadline := time.Now().Add(60 * time.Second)
	for {
		var found bool
		_ = tx.InTenant(ctx, tenant, func(ctx context.Context) error {
			_, found, err = persistence.MembershipStore{}.Membership(ctx, tenant, envelope.Payload.Subject)
			return err
		})
		if found {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("the replica did not resolve the member within 60 s")
		}
		time.Sleep(200 * time.Millisecond)
	}
	if err := consumer.Healthy(); err != nil {
		t.Errorf("healthy: %v", err)
	}
	var text strings.Builder
	metrics.Write(&text)
	for _, line := range []string{
		`hoops_roster_replica_parked_total{topic="core.person"} 1`,
		`hoops_roster_replica_events_total{topic="core.tenant",outcome="applied"} 1`,
		`hoops_roster_replica_events_total{topic="core.person",outcome="applied"} 1`,
	} {
		if !strings.Contains(text.String(), line) {
			t.Errorf("missing %s in\n%s", line, text.String())
		}
	}
}
