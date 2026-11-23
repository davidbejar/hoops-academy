package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import jakarta.persistence.Query;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** CORE-05: one way to rebind an RLS setting for a few statements and put it back, also after a failure. */
class SessionSettingsTest {

    private final List<String> bound = new ArrayList<>();
    private final EntityManager em = mock(EntityManager.class);

    @Test
    void theStatementsRunUnderTheNewValueAndTheOldOneIsBoundAfterwards() {
        recordingBinds();

        String seen = SessionSettings.with(em, SessionSettings.TENANT, "other", "home", () -> bound.getLast());

        assertThat(seen).isEqualTo("app.tenant_id=other");
        assertThat(bound).containsExactly("app.tenant_id=other", "app.tenant_id=home");
    }

    @Test
    void aFailureRestoresTheOldValueAndIsRethrown() {
        recordingBinds();
        IllegalStateException failure = new IllegalStateException("statement failed");

        assertThatThrownBy(() -> SessionSettings.with(em, SessionSettings.SUBJECT, "sub", "", () -> {
            throw failure;
        })).isSameAs(failure);

        assertThat(bound).containsExactly("app.subject=sub", "app.subject=");
    }

    @Test
    void aRestoreThatFailsOnTheAbortedTransactionDoesNotHideTheCause() {
        recordingBinds();
        IllegalStateException failure = new IllegalStateException("statement failed");
        PersistenceException aborted = new PersistenceException("current transaction is aborted");

        assertThatThrownBy(() -> SessionSettings.with(em, SessionSettings.TENANT, "other", "home", () -> {
            failNextBind(aborted);
            throw failure;
        })).isSameAs(failure).hasSuppressedException(aborted);
    }

    @Test
    void theNilTenantIsTheZeroUuid() {
        assertThat(SessionSettings.NIL_TENANT).isEqualTo(new java.util.UUID(0, 0).toString());
    }

    private RuntimeException nextFailure;

    private void failNextBind(RuntimeException failure) {
        nextFailure = failure;
    }

    private void recordingBinds() {
        when(em.createNativeQuery(anyString())).thenAnswer(invocation -> {
            Query query = mock(Query.class);
            String[] name = new String[1];
            when(query.setParameter(org.mockito.ArgumentMatchers.eq("name"), org.mockito.ArgumentMatchers.any()))
                    .thenAnswer(set -> {
                        name[0] = set.getArgument(1);
                        return query;
                    });
            when(query.setParameter(org.mockito.ArgumentMatchers.eq("value"), org.mockito.ArgumentMatchers.any()))
                    .thenAnswer(set -> {
                        if (nextFailure != null) {
                            RuntimeException failure = nextFailure;
                            nextFailure = null;
                            throw failure;
                        }
                        bound.add(name[0] + "=" + set.getArgument(1));
                        return query;
                    });
            return query;
        });
    }
}
