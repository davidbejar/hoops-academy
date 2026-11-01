package com.hoopsacademy.common.tenancy;

import io.agroal.api.AgroalDataSource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.TransactionSynchronizationRegistry;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Binds the context tenant to the current JTA transaction's database session with
 * {@code select set_config('app.tenant_id', ?, true)}. The setting is transaction-local ({@code is_local = true}),
 * so it disappears at commit/rollback and can never leak to the next user of a pooled connection.
 *
 * <p>Within a JTA transaction Agroal hands out the one connection enlisted in that transaction, which is the same
 * connection Hibernate uses. A marker in the {@link TransactionSynchronizationRegistry} avoids repeating the
 * statement when nested {@code REQUIRED}/{@code MANDATORY} methods join the transaction.
 */
@ApplicationScoped
public class TenantTransactions {

    private static final String SET_TENANT_SQL = "select set_config('app.tenant_id', ?, true)";
    private static final String BOUND_TENANT_KEY = TenantTransactions.class.getName() + ".boundTenant";

    private final AgroalDataSource dataSource;
    private final TransactionSynchronizationRegistry transactions;
    private final CurrentTenant currentTenant;

    public TenantTransactions(
            AgroalDataSource dataSource, TransactionSynchronizationRegistry transactions, CurrentTenant currentTenant) {
        this.dataSource = dataSource;
        this.transactions = transactions;
        this.currentTenant = currentTenant;
    }

    /** No-op when no transaction is active or no tenant is bound (RLS then fails loudly, by design). */
    public void bindCurrentTransaction() {
        if (transactions.getTransactionKey() == null) {
            return;
        }
        currentTenant.tenantId().filter(tenant -> !tenant.equals(transactions.getResource(BOUND_TENANT_KEY)))
                .ifPresent(this::setOnTransactionConnection);
    }

    private void setOnTransactionConnection(TenantId tenant) {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement(SET_TENANT_SQL)) {
            statement.setString(1, tenant.toString());
            statement.execute();
        } catch (SQLException e) {
            throw new IllegalStateException("Could not bind tenant to the transaction", e);
        }
        transactions.putResource(BOUND_TENANT_KEY, tenant);
    }
}
