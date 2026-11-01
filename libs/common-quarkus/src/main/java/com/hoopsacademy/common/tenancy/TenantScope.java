package com.hoopsacademy.common.tenancy;

import io.agroal.api.AgroalDataSource;
import io.quarkus.arc.Arc;
import io.quarkus.arc.ManagedContext;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.InvalidTransactionException;
import jakarta.transaction.NotSupportedException;
import jakarta.transaction.SystemException;
import jakarta.transaction.Transaction;
import jakarta.transaction.TransactionManager;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.util.function.Supplier;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Runs work for one tenant outside an HTTP request (scheduled jobs, consumers): activates a request context if
 * needed, binds the tenant, runs the work in its OWN new transaction with {@code app.tenant_id} set, then
 * restores the previous binding (i.e. clears it for jobs). The work has no caller, so no {@link AuthzContext}.
 * {@link #runExclusive} lets exactly one replica run a scheduled job at a time.
 */
@ApplicationScoped
public class TenantScope {

    private static final Logger LOG = Logger.getLogger(TenantScope.class);

    private final TenantContext tenantContext;
    private final TenantTransactions tenantTransactions;
    private final AgroalDataSource dataSource;
    private final TransactionManager transactionManager;
    private final Duration exclusiveLockTimeout;

    public TenantScope(TenantContext tenantContext, TenantTransactions tenantTransactions, AgroalDataSource dataSource,
            TransactionManager transactionManager,
            @ConfigProperty(name = "hoops.tenancy.exclusive-lock-timeout", defaultValue = "PT6H") Duration exclusiveLockTimeout) {
        this.tenantContext = tenantContext;
        this.tenantTransactions = tenantTransactions;
        this.dataSource = dataSource;
        this.transactionManager = transactionManager;
        this.exclusiveLockTimeout = exclusiveLockTimeout;
    }

    /**
     * Runs {@code work} only if no other caller (in any replica) currently holds the cluster-wide lock {@code lockKey}:
     * a transaction-scoped Postgres advisory lock ({@code pg_try_advisory_xact_lock}) taken in a dedicated lock
     * transaction. That transaction is SUSPENDED while the work runs, so the work starts without a transaction and its
     * own transactions ({@link #runAs}, {@code @Transactional}, other datasources) commit independently; afterwards the
     * lock transaction is rolled back, which releases the lock (it is also released if the process or connection dies,
     * or when {@code hoops.tenancy.exclusive-lock-timeout} — default 6 h — expires). Never waits for the lock.
     *
     * @return true when the work ran here, false when another holder was running it (the call is skipped)
     * @throws IllegalStateException when called inside a transaction (jobs call it from the scheduler thread)
     */
    public boolean runExclusive(String lockKey, Runnable work) {
        ManagedContext requestContext = Arc.container().requestContext();
        boolean activatedHere = !requestContext.isActive();
        if (activatedHere) {
            requestContext.activate();
        }
        try {
            return lockedRun(lockKey, work);
        } finally {
            if (activatedHere) {
                requestContext.terminate();
            }
        }
    }

    private boolean lockedRun(String lockKey, Runnable work) {
        Transaction lockTransaction = beginLockTransaction(lockKey);
        try {
            if (!tryAdvisoryLock(advisoryKey(lockKey))) {
                LOG.infof("Skipping %s: another instance holds its lock", lockKey);
                return false;
            }
            suspend();
            try {
                work.run();
            } finally {
                resume(lockTransaction);
            }
            return true;
        } finally {
            rollbackQuietly(lockKey);
        }
    }

    private Transaction beginLockTransaction(String lockKey) {
        try {
            if (transactionManager.getTransaction() != null) {
                throw new IllegalStateException("runExclusive(" + lockKey + ") must not run inside a transaction");
            }
            transactionManager.setTransactionTimeout((int) Math.min(Integer.MAX_VALUE, exclusiveLockTimeout.toSeconds()));
            try {
                transactionManager.begin();
            } finally {
                transactionManager.setTransactionTimeout(0);
            }
            return transactionManager.getTransaction();
        } catch (SystemException | NotSupportedException e) {
            throw new IllegalStateException("Could not begin the lock transaction for " + lockKey, e);
        }
    }

    private void suspend() {
        try {
            transactionManager.suspend();
        } catch (SystemException e) {
            throw new IllegalStateException("Could not suspend the lock transaction", e);
        }
    }

    private void resume(Transaction lockTransaction) {
        try {
            transactionManager.resume(lockTransaction);
        } catch (InvalidTransactionException | SystemException e) {
            LOG.warnf("Lock transaction could not be resumed (timed out?): %s", e.toString());
        }
    }

    private void rollbackQuietly(String lockKey) {
        try {
            if (transactionManager.getTransaction() != null) {
                transactionManager.rollback();
            }
        } catch (SystemException | IllegalStateException e) {
            LOG.warnf("Releasing the lock of %s failed (released when the connection closes): %s", lockKey, e.toString());
        }
    }

    /** Stable 64-bit advisory lock key of a lock name (first 8 bytes of its SHA-256), equal in every JVM. */
    public static long advisoryKey(String lockKey) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(lockKey.getBytes(StandardCharsets.UTF_8));
            return ByteBuffer.wrap(digest).getLong();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is always available", e);
        }
    }

    private boolean tryAdvisoryLock(long key) {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("select pg_try_advisory_xact_lock(?)")) {
            statement.setLong(1, key);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getBoolean(1);
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not request advisory lock " + key, e);
        }
    }

    public <T> T runAs(TenantId tenant, Supplier<T> work) {
        ManagedContext requestContext = Arc.container().requestContext();
        boolean activatedHere = !requestContext.isActive();
        if (activatedHere) {
            requestContext.activate();
        }
        try {
            return runBound(tenant, work);
        } finally {
            if (activatedHere) {
                requestContext.terminate();
            }
        }
    }

    public void runAs(TenantId tenant, Runnable work) {
        runAs(tenant, () -> {
            work.run();
            return null;
        });
    }

    private <T> T runBound(TenantId tenant, Supplier<T> work) {
        TenantContext.Snapshot previous = tenantContext.snapshot();
        tenantContext.bindTenant(tenant);
        try {
            return QuarkusTransaction.requiringNew().call(() -> {
                tenantTransactions.bindCurrentTransaction();
                return work.get();
            });
        } finally {
            tenantContext.restore(previous);
        }
    }
}
