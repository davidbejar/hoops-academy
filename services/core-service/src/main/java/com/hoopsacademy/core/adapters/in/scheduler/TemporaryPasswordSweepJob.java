package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.identity.ExpireTemporaryPasswords;
import com.hoopsacademy.core.application.port.TemporaryPasswordSweeps;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Status;
import jakarta.transaction.Synchronization;
import jakarta.transaction.TransactionSynchronizationRegistry;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.atomic.AtomicBoolean;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Runs the temporary password sweep (ADR-0028) without a scheduler: {@link #request} hands it to one background thread
 * after the requesting transaction commits, and {@link #run} takes the cluster-wide lock {@value #LOCK}, so one replica
 * sweeps at a time (another one skips). At most one sweep waits behind the running one in this replica: it sees every
 * row the events before it committed. {@code hoops.temporary-password.sweep-on-events=false} turns the events off
 * (tests call {@link #run} directly).
 */
@ApplicationScoped
public class TemporaryPasswordSweepJob implements TemporaryPasswordSweeps {

    /** Cluster-wide lock name ({@code TenantScope.runExclusive}). */
    public static final String LOCK = "core.temporary_password_sweep";

    private static final Logger LOG = Logger.getLogger(TemporaryPasswordSweepJob.class);

    private final ExpireTemporaryPasswords sweep;
    private final TenantScope tenantScope;
    private final TransactionSynchronizationRegistry transactions;
    private final boolean onEvents;
    private final ExecutorService background = Executors.newSingleThreadExecutor(work -> {
        Thread thread = new Thread(work, "temporary-password-sweep");
        thread.setDaemon(true);
        return thread;
    });
    private final AtomicBoolean waiting = new AtomicBoolean();

    public TemporaryPasswordSweepJob(ExpireTemporaryPasswords sweep, TenantScope tenantScope,
            TransactionSynchronizationRegistry transactions,
            @ConfigProperty(name = "hoops.temporary-password.sweep-on-events", defaultValue = "true") boolean onEvents) {
        this.sweep = sweep;
        this.tenantScope = tenantScope;
        this.transactions = transactions;
        this.onEvents = onEvents;
    }

    /** One sweep under the cluster lock; false when another replica holds it (this call is skipped). */
    public boolean run() {
        return tenantScope.runExclusive(LOCK, () -> {
            ExpireTemporaryPasswords.Summary summary = sweep.run();
            if (summary.examined() > 0) {
                LOG.infof("Temporary password sweep: %d due, %d expired, %d already replaced, %d failed",
                        summary.examined(), summary.expired(), summary.forgotten(), summary.failed());
            }
        });
    }

    @Override
    public void request() {
        if (!onEvents) {
            return;
        }
        try {
            if (transactions.getTransactionKey() == null) {
                submit();
            } else {
                transactions.registerInterposedSynchronization(new AfterCommit());
            }
        } catch (RuntimeException e) {
            LOG.warnf("Temporary password sweep not requested: %s", e.toString());
        }
    }

    private void submit() {
        if (!waiting.compareAndSet(false, true)) {
            return; // a sweep is already waiting to start; it will see this event's rows
        }
        try {
            background.execute(() -> {
                waiting.set(false);
                runQuietly();
            });
        } catch (RejectedExecutionException e) {
            waiting.set(false); // shutting down
        }
    }

    private void runQuietly() {
        try {
            run();
        } catch (RuntimeException e) {
            LOG.warnf("Temporary password sweep failed, the next event retries: %s", e.toString());
        }
    }

    @PreDestroy
    void stop() {
        background.shutdownNow();
    }

    private final class AfterCommit implements Synchronization {
        @Override
        public void beforeCompletion() {
            // nothing to do before the commit
        }

        @Override
        public void afterCompletion(int status) {
            if (status == Status.STATUS_COMMITTED) {
                submit();
            }
        }
    }
}
