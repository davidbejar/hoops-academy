package com.hoopsacademy.core.adapters.out.platform;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.AcademyRequestRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.signup.AcademyName;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import com.hoopsacademy.core.domain.signup.AcademyRequestId;
import com.hoopsacademy.core.domain.signup.AcademyRequestStatus;
import com.hoopsacademy.core.domain.signup.Requester;
import com.hoopsacademy.core.domain.signup.RequesterRole;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceException;
import jakarta.persistence.Query;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.hibernate.exception.ConstraintViolationException;

/** {@code core.academy_request} as core_platform (V17); names are compared with {@code core.academy_name_key}. */
@ApplicationScoped
class PlatformAcademyRequestRepository implements AcademyRequestRepository {

    private static final String OPEN_NAME_INDEX = "academy_request_open_name_uq";
    private static final String COLUMNS = """
            id, status, requester_name, email, requester_role, academy_name, locale, requested_at, decided_at,
            decided_by, reason, created_tenant_id, notified_at""";
    private static final String NEWEST_FIRST = " order by requested_at desc, id";

    private final EntityManager em;

    PlatformAcademyRequestRepository(@PersistenceUnit("platform") EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(AcademyRequest request) {
        Requester requester = request.requester();
        Query insert = em.createNativeQuery("""
                insert into core.academy_request (id, status, requester_name, email, requester_role, academy_name,
                                                  locale, requested_at)
                values (:id, 'PENDING', cast(:name as text), :email, :role, :academyName, :locale, :requestedAt)""")
                .setParameter("id", request.id().value())
                .setParameter("name", requester.name().orElse(null))
                .setParameter("email", requester.email())
                .setParameter("role", requester.role().name())
                .setParameter("academyName", request.academyName().value())
                .setParameter("locale", requester.locale().code())
                .setParameter("requestedAt", request.requestedAt());
        try {
            insert.executeUpdate();
        } catch (PersistenceException e) {
            if (isOpenNameViolation(e)) {
                throw new ConflictException("An academy with this name has been requested", "ACADEMY_NAME_TAKEN");
            }
            throw e;
        }
    }

    @Override
    public boolean tenantNamed(AcademyName name) {
        return exists("""
                select count(*) from core.tenant
                 where core.academy_name_key(name) = core.academy_name_key(:name)""", name);
    }

    @Override
    public boolean openRequestNamed(AcademyName name) {
        return exists("""
                select count(*) from core.academy_request
                 where core.academy_name_key(academy_name) = core.academy_name_key(:name)
                   and status in ('PENDING', 'ACCEPTED')""", name);
    }

    @Override
    public long pendingFor(String email) {
        return ((Number) em.createNativeQuery("""
                select count(*) from core.academy_request where lower(email) = lower(:email) and status = 'PENDING'""")
                .setParameter("email", email).getSingleResult()).longValue();
    }

    @Override
    public Optional<AcademyRequest> find(AcademyRequestId id) {
        List<Object[]> rows = rows(em.createNativeQuery("select " + COLUMNS + " from core.academy_request where id = :id",
                Object[].class).setParameter("id", id.value()));
        return rows.stream().findFirst().map(PlatformAcademyRequestRepository::toDomain);
    }

    @Override
    public PageResult<AcademyRequest> list(Optional<AcademyRequestStatus> status, PageRequest page) {
        String where = status.isPresent() ? " where status = :status" : "";
        Query items = em.createNativeQuery("select " + COLUMNS + " from core.academy_request" + where + NEWEST_FIRST,
                Object[].class);
        Query total = em.createNativeQuery("select count(*) from core.academy_request" + where);
        status.ifPresent(value -> {
            items.setParameter("status", value.name());
            total.setParameter("status", value.name());
        });
        List<AcademyRequest> found = rows(items.setFirstResult(page.offset()).setMaxResults(page.size())).stream()
                .map(PlatformAcademyRequestRepository::toDomain).toList();
        return new PageResult<>(found, page, ((Number) total.getSingleResult()).longValue());
    }

    @Override
    public boolean decide(AcademyRequest decided) {
        Query update = switch (decided.status()) {
            case ACCEPTED -> em.createNativeQuery("""
                    update core.academy_request
                       set status = 'ACCEPTED', decided_at = :at, decided_by = :by, created_tenant_id = :tenant
                     where id = :id and status = 'PENDING'""")
                    .setParameter("tenant", decided.tenantId().value());
            case REJECTED -> em.createNativeQuery("""
                    update core.academy_request
                       set status = 'REJECTED', decided_at = :at, decided_by = :by, reason = :reason
                     where id = :id and status = 'PENDING'""")
                    .setParameter("reason", decided.reason());
            case PENDING -> throw new IllegalArgumentException("A pending request is not a decision");
        };
        return update.setParameter("at", decided.decidedAt()).setParameter("by", decided.decidedBy())
                .setParameter("id", decided.id().value()).executeUpdate() == 1;
    }

    @Override
    public void reopen(AcademyRequestId id, TenantId tenant) {
        em.createNativeQuery("""
                update core.academy_request
                   set status = 'PENDING', decided_at = null, decided_by = null, created_tenant_id = null,
                       notified_at = null
                 where id = :id and status = 'ACCEPTED' and created_tenant_id = :tenant""")
                .setParameter("id", id.value()).setParameter("tenant", tenant.value()).executeUpdate();
    }

    @Override
    public void markNotified(AcademyRequest notified) {
        em.createNativeQuery("update core.academy_request set notified_at = :at where id = :id and status <> 'PENDING'")
                .setParameter("at", notified.notifiedAt()).setParameter("id", notified.id().value()).executeUpdate();
    }

    private boolean exists(String countSql, AcademyName name) {
        return ((Number) em.createNativeQuery(countSql).setParameter("name", name.value()).getSingleResult())
                .longValue() > 0;
    }

    @SuppressWarnings("unchecked")
    private static List<Object[]> rows(Query query) {
        return query.getResultList();
    }

    private static boolean isOpenNameViolation(PersistenceException e) {
        for (Throwable cause = e; cause != null; cause = cause.getCause()) {
            if (cause instanceof ConstraintViolationException violation
                    && OPEN_NAME_INDEX.equals(violation.getConstraintName())) {
                return true;
            }
        }
        return false;
    }

    private static AcademyRequest toDomain(Object[] row) {
        Requester requester = Requester.of((String) row[2], (String) row[3], RequesterRole.valueOf((String) row[4]),
                AppLocale.fromCode((String) row[6]));
        return new AcademyRequest(new AcademyRequestId((UUID) row[0]), AcademyRequestStatus.valueOf((String) row[1]),
                requester, AcademyName.of((String) row[5]), instant(row[7]), instant(row[8]), (String) row[9],
                (String) row[10], row[11] == null ? null : new TenantId((UUID) row[11]), instant(row[12]));
    }

    private static Instant instant(Object value) {
        return switch (value) {
            case null -> null;
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case java.sql.Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Not a timestamp: " + value.getClass());
        };
    }
}
