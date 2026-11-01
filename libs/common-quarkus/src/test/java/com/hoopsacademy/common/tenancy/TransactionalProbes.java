package com.hoopsacademy.common.tenancy;

import io.agroal.api.AgroalDataSource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import jakarta.transaction.Transactional.TxType;
import java.util.List;

/** Test beans whose transactional methods report what the database session sees. */
class TransactionalProbes {

    @ApplicationScoped
    static class Outer {
        private final AgroalDataSource dataSource;
        private final Inner inner;

        Outer(AgroalDataSource dataSource, Inner inner) {
            this.dataSource = dataSource;
            this.inner = inner;
        }

        @Transactional
        SessionProbe required() {
            return SessionProbe.of(dataSource);
        }

        @Transactional
        List<SessionProbe> requiredThenRequiresNew() {
            SessionProbe outer = SessionProbe.of(dataSource);
            return List.of(outer, inner.requiresNew(), inner.mandatory(), SessionProbe.of(dataSource));
        }

        @Transactional(TxType.SUPPORTS)
        SessionProbe supportsWithoutTransaction() {
            return SessionProbe.of(dataSource);
        }
    }

    @ApplicationScoped
    static class Inner {
        private final AgroalDataSource dataSource;

        Inner(AgroalDataSource dataSource) {
            this.dataSource = dataSource;
        }

        @Transactional(TxType.REQUIRES_NEW)
        SessionProbe requiresNew() {
            return SessionProbe.of(dataSource);
        }

        @Transactional(TxType.MANDATORY)
        SessionProbe mandatory() {
            return SessionProbe.of(dataSource);
        }
    }
}
