package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.domain.identity.TemporaryPasswordStatus;
import com.hoopsacademy.core.domain.identity.UserId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** The temporary-password columns of {@code core.app_user} (V10), native SQL as core_app; the table has no RLS. */
@ApplicationScoped
class JpaTemporaryPasswordLoginRepository implements TemporaryPasswordLogins {

    private final EntityManager em;

    JpaTemporaryPasswordLoginRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public boolean issued(String subject, Instant at) {
        List<?> previous = em.createNativeQuery("""
                select temporary_password_expired_at is not null from core.app_user
                 where keycloak_sub = :sub for update""")
                .setParameter("sub", subject)
                .getResultList();
        if (previous.isEmpty()) {
            throw new IllegalStateException("No registered login for the subject of a temporary password");
        }
        em.createNativeQuery("""
                update core.app_user set temporary_password_issued_at = :at, temporary_password_expired_at = null
                 where keycloak_sub = :sub""")
                .setParameter("at", utc(at))
                .setParameter("sub", subject)
                .executeUpdate();
        return (Boolean) previous.get(0);
    }

    @Override
    public List<String> due(Instant issuedBefore) {
        return em.createNativeQuery("""
                select keycloak_sub from core.app_user
                 where temporary_password_issued_at < :cutoff and temporary_password_expired_at is null
                 order by temporary_password_issued_at""", String.class)
                .setParameter("cutoff", utc(issuedBefore))
                .getResultList();
    }

    @Override
    public Optional<UserId> lockIfDue(String subject, Instant issuedBefore) {
        List<?> rows = em.createNativeQuery("""
                select id from core.app_user
                 where keycloak_sub = :sub and temporary_password_issued_at < :cutoff
                   and temporary_password_expired_at is null
                 for update""")
                .setParameter("sub", subject)
                .setParameter("cutoff", utc(issuedBefore))
                .getResultList();
        return rows.stream().findFirst().map(id -> new UserId((UUID) id));
    }

    @Override
    public void expired(String subject, Instant at) {
        em.createNativeQuery("update core.app_user set temporary_password_expired_at = :at where keycloak_sub = :sub")
                .setParameter("at", utc(at))
                .setParameter("sub", subject)
                .executeUpdate();
    }

    @Override
    public void used(String subject) {
        em.createNativeQuery("""
                update core.app_user set temporary_password_issued_at = null
                 where keycloak_sub = :sub and temporary_password_issued_at is not null""")
                .setParameter("sub", subject)
                .executeUpdate();
    }

    @Override
    public Map<UserId, TemporaryPasswordStatus> statusOf(Collection<UserId> logins) {
        Map<UserId, TemporaryPasswordStatus> statuses = new HashMap<>();
        if (logins.isEmpty()) {
            return statuses;
        }
        List<?> rows = em.createNativeQuery("""
                select id, temporary_password_issued_at, temporary_password_expired_at from core.app_user
                 where id in (:ids)""")
                .setParameter("ids", logins.stream().map(UserId::value).distinct().toList())
                .getResultList();
        rows.stream().map(Object[].class::cast).forEach(row -> statuses.put(new UserId((UUID) row[0]),
                TemporaryPasswordStatus.of(instant(row[1]), instant(row[2]))));
        return statuses;
    }

    private static OffsetDateTime utc(Instant at) {
        return OffsetDateTime.ofInstant(at, java.time.ZoneOffset.UTC);
    }

    private static Instant instant(Object value) {
        return switch (value) {
            case null -> null;
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Unexpected timestamp type " + value.getClass());
        };
    }
}
