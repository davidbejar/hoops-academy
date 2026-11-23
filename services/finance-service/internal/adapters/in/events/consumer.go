package events

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"github.com/twmb/franz-go/pkg/kgo"
	"github.com/twmb/franz-go/pkg/sasl/scram"

	"hoopsacademy.local/finance/internal/adapters/out/persistence"
	"hoopsacademy.local/finance/internal/application"
)

// Config is the broker client (the chart's KAFKA_* environment, WP71).
type Config struct {
	Brokers []string
	Group   string // finance-service.roster (the ACL's group prefix is finance-service.)
	// SASL/SCRAM-SHA-256 when User is set (SASL_PLAINTEXT on kind and in the cloud; compose's Redpanda has no auth).
	User, Password string
}

// Parker writes invalid records.
type Parker interface {
	Park(ctx context.Context, parked persistence.Parked) error
}

// Consumer reads the topics and applies them.
type Consumer struct {
	client  *kgo.Client
	decoder *Decoder
	replica application.Replica
	parker  Parker
	metrics *Metrics
	log     *slog.Logger
	failed  atomic.Pointer[error]
}

// attempts of an apply that fails for another reason than the contract (the database) before the consumer stops.
const attempts = 3

// NewConsumer connects lazily; offsets start at the beginning of the compacted topics for a new group.
func NewConsumer(config Config, decoder *Decoder, replica application.Replica, parker Parker, metrics *Metrics,
	log *slog.Logger) (*Consumer, error) {
	options := []kgo.Opt{
		kgo.SeedBrokers(config.Brokers...), kgo.ConsumerGroup(config.Group), kgo.ConsumeTopics(Topics...),
		kgo.DisableAutoCommit(), kgo.ConsumeResetOffset(kgo.NewOffset().AtStart()),
		kgo.ClientID("finance-service"),
	}
	if config.User != "" {
		options = append(options, kgo.SASL(scram.Auth{User: config.User, Pass: config.Password}.AsSha256Mechanism()))
	}
	client, err := kgo.NewClient(options...)
	if err != nil {
		return nil, fmt.Errorf("kafka client: %w", err)
	}
	return &Consumer{client: client, decoder: decoder, replica: replica, parker: parker, metrics: metrics, log: log}, nil
}

// Run consumes until ctx ends or an apply keeps failing; then the consumer is unhealthy (liveness DOWN: the
// orchestrator restarts the pod, which resumes from the last committed offset, ADR-0037 §5).
func (c *Consumer) Run(ctx context.Context) error {
	defer c.client.Close()
	for {
		fetches := c.client.PollFetches(ctx)
		if ctx.Err() != nil {
			return nil
		}
		fetches.EachError(func(topic string, partition int32, err error) {
			c.log.WarnContext(ctx, "fetch failed", slog.String("topic", topic), slog.Int("partition", int(partition)),
				slog.String("error", err.Error()))
		})
		var records []*kgo.Record
		var failure error
		fetches.EachRecord(func(record *kgo.Record) {
			if failure == nil {
				if failure = c.handle(ctx, record); failure == nil {
					records = append(records, record)
				}
			}
		})
		if len(records) > 0 {
			if err := c.client.CommitRecords(ctx, records...); err != nil && ctx.Err() == nil {
				c.log.WarnContext(ctx, "offset commit failed", slog.String("error", err.Error()))
			}
		}
		if failure != nil {
			c.failed.Store(&failure)
			c.log.ErrorContext(ctx, "roster consumer stopped", slog.String("error", failure.Error()))
			return failure
		}
	}
}

// handle applies one record: parked when invalid, retried in place when the database fails.
func (c *Consumer) handle(ctx context.Context, record *kgo.Record) error {
	event, skip, err := c.decoder.Decode(record.Topic, record.Key, record.Value)
	if skip {
		c.metrics.event(record.Topic, "tombstone")
		return nil
	}
	var invalid *Invalid
	if errors.As(err, &invalid) {
		c.metrics.parked(record.Topic)
		c.log.WarnContext(ctx, "roster event parked", slog.String("topic", record.Topic),
			slog.Int64("offset", record.Offset), slog.String("reason", invalid.Reason))
		return c.parker.Park(ctx, persistence.Parked{Topic: record.Topic, Partition: record.Partition,
			Offset: record.Offset, Key: string(record.Key), EventID: invalid.EventID, Reason: invalid.Reason})
	}
	if err != nil {
		return err
	}
	for attempt := 1; ; attempt++ {
		outcome, err := c.replica.Apply(ctx, event)
		if err == nil {
			c.metrics.event(record.Topic, outcome)
			return nil
		}
		if attempt == attempts || ctx.Err() != nil {
			return fmt.Errorf("apply %s offset %d: %w", record.Topic, record.Offset, err)
		}
		time.Sleep(time.Duration(attempt) * 500 * time.Millisecond)
	}
}

// Healthy is nil while the consumer runs (the health checks' liveness).
func (c *Consumer) Healthy() error {
	if failed := c.failed.Load(); failed != nil {
		return *failed
	}
	return nil
}

// Metrics counts what the consumer did: hoops_roster_replica_events_total{topic,outcome} and
// hoops_roster_replica_parked_total{topic}, and what the retention deleted: hoops_roster_replica_pruned_total{table},
// the names of the Java services.
type Metrics struct {
	mu     sync.Mutex
	events map[[2]string]uint64
	park   map[string]uint64
	pruned uint64
}

// NewMetrics starts every topic's parked count at 0.
func NewMetrics() *Metrics {
	m := &Metrics{events: map[[2]string]uint64{}, park: map[string]uint64{}}
	for _, topic := range Topics {
		m.park[topic] = 0
	}
	return m
}

func (m *Metrics) event(topic, outcome string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.events[[2]string{topic, outcome}]++
}

func (m *Metrics) parked(topic string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.park[topic]++
}

// PrunedAppliedEvents counts n applied event ids the retention deleted.
func (m *Metrics) PrunedAppliedEvents(n int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.pruned += uint64(max(n, 0))
}

// Write writes the counters in the Prometheus text format.
func (m *Metrics) Write(w io.Writer) {
	m.mu.Lock()
	defer m.mu.Unlock()
	_, _ = fmt.Fprint(w, "# TYPE hoops_roster_replica_events_total counter\n")
	keys := make([][2]string, 0, len(m.events))
	for k := range m.events {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool { return keys[i][0]+keys[i][1] < keys[j][0]+keys[j][1] })
	for _, k := range keys {
		_, _ = fmt.Fprintf(w, "hoops_roster_replica_events_total{topic=%q,outcome=%q} %d\n", k[0], k[1], m.events[k])
	}
	_, _ = fmt.Fprint(w, "# TYPE hoops_roster_replica_parked_total counter\n")
	for _, topic := range Topics {
		_, _ = fmt.Fprintf(w, "hoops_roster_replica_parked_total{topic=%q} %d\n", topic, m.park[topic])
	}
	_, _ = fmt.Fprint(w, "# TYPE hoops_roster_replica_pruned_total counter\n")
	_, _ = fmt.Fprintf(w, "hoops_roster_replica_pruned_total{table=\"applied_event\"} %d\n", m.pruned)
}
