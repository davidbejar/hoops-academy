package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.RollbackException;
import jakarta.transaction.Synchronization;
import jakarta.transaction.SystemException;
import jakarta.transaction.TransactionManager;
import jakarta.transaction.TransactionSynchronizationRegistry;
import java.util.ArrayList;
import java.util.List;
import org.jboss.logging.Logger;

/**
 * The domain-event collector of the roster events (WP67): the repositories, the only writers of the roster tables,
 * report each aggregate they change here, so every use case, present or future, publishes its changes without
 * knowing about events. The changes of one transaction are collected per transaction and appended to the outbox by
 * {@link RosterEventAppender} just before that transaction commits (a JTA synchronization that runs before
 * Hibernate's flush synchronization), in the same transaction: the change and its event commit or roll back together.
 * A transaction changes the roster of one tenant: the tenant bound when the first change is reported.
 */
@ApplicationScoped
public class RosterChanges {

    private static final Logger LOG = Logger.getLogger(RosterChanges.class);
    private static final String BATCH_KEY = RosterChanges.class.getName() + ".batch";

    private final TransactionManager transactionManager;
    private final TransactionSynchronizationRegistry transactions;
    private final TenantContext tenantContext;
    private final RosterEventAppender appender;

    public RosterChanges(TransactionManager transactionManager, TransactionSynchronizationRegistry transactions,
            TenantContext tenantContext, RosterEventAppender appender) {
        this.transactionManager = transactionManager;
        this.transactions = transactions;
        this.tenantContext = tenantContext;
        this.appender = appender;
    }

    public void person(PersonId id) {
        record(new RosterChange.Person(id));
    }

    public void player(PlayerId id) {
        record(new RosterChange.Player(id));
    }

    public void team(TeamId id) {
        record(new RosterChange.Team(id));
    }

    public void season(SeasonId id) {
        record(new RosterChange.Season(id));
    }

    public void teamPlayer(TeamPlayerId id) {
        record(new RosterChange.TeamPlayer(id));
    }

    public void teamStaff(TeamId team, PersonId person) {
        record(new RosterChange.TeamStaff(team, person));
    }

    public void guardianLink(GuardianLinkId id, PersonId guardian, PlayerId player) {
        record(new RosterChange.GuardianLink(id, guardian, player));
    }

    /** The bound tenant's own record (academy profile, onboarding). */
    public void tenant() {
        record(new RosterChange.Tenant());
    }

    /** Any change, e.g. the events backfill republishing an aggregate that has no event yet (WP81). */
    public void report(RosterChange change) {
        record(change);
    }

    private void record(RosterChange change) {
        if (transactions.getTransactionKey() == null) {
            throw new IllegalStateException("Roster changes are written inside a transaction: " + change);
        }
        TenantId tenant = tenantContext.requireTenantId();
        Batch batch = (Batch) transactions.getResource(BATCH_KEY);
        if (batch == null) {
            batch = new Batch(tenant);
            transactions.putResource(BATCH_KEY, batch);
            register(batch);
        } else if (!batch.tenant.equals(tenant)) {
            throw new IllegalStateException("One transaction changes the roster of one tenant: " + batch.tenant
                    + " and " + tenant);
        }
        batch.changes.add(change);
    }

    /** A plain (not interposed) synchronization: it runs before Hibernate's, while the session is still open. */
    private void register(Batch batch) {
        try {
            transactionManager.getTransaction().registerSynchronization(batch);
        } catch (RollbackException e) {
            throw new IllegalStateException("The transaction is marked for rollback", e);
        } catch (SystemException e) {
            throw new IllegalStateException("Could not register the roster events of the transaction", e);
        }
    }

    private final class Batch implements Synchronization {

        private final TenantId tenant;
        private final List<RosterChange> changes = new ArrayList<>();

        private Batch(TenantId tenant) {
            this.tenant = tenant;
        }

        @Override
        public void beforeCompletion() {
            try {
                appender.append(tenant, changes);
            } catch (RuntimeException e) {
                LOG.errorf(e, "Roster events of tenant %s could not be appended; the transaction rolls back", tenant);
                throw e;
            }
        }

        @Override
        public void afterCompletion(int status) {
            // nothing to release: the batch lives in the transaction's resources
        }
    }
}
