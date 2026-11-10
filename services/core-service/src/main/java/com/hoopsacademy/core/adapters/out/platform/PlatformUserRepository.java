package com.hoopsacademy.core.adapters.out.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PlatformUsers;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Every login and its persons as core_platform (V18: select policies and column grants on app_user, person,
 * membership_role). Two statements per page whatever its size: the count, and the page's logins left-joined to their
 * persons, academies and roles (no query per login). The transaction binds the nil tenant first, so the standard tenant
 * policy matches nothing instead of raising.
 */
@ApplicationScoped
class PlatformUserRepository implements PlatformUsers {

    private static final String NIL_TENANT = "00000000-0000-0000-0000-000000000000";
    private static final String MATCHES = """
             where lower(u.email) like :q escape '\\'
                or exists (select 1 from core.person p
                            where p.user_id = u.id
                              and lower(p.given_name || ' ' || p.family_name) like :q escape '\\')""";

    private final EntityManager em;

    PlatformUserRepository(@PersistenceUnit("platform") EntityManager em) {
        this.em = em;
    }

    @Override
    public PageResult<Login> list(Optional<String> query, PageRequest page) {
        em.createNativeQuery("select set_config('app.tenant_id', :nil, true)").setParameter("nil", NIL_TENANT)
                .getSingleResult();
        Optional<String> pattern = query.map(PlatformUserRepository::containsPattern);
        String where = pattern.isPresent() ? MATCHES : "";
        Query count = em.createNativeQuery("select count(*) from core.app_user u " + where);
        Query items = em.createNativeQuery("with page as (select u.id, u.email, u.created_at from core.app_user u "
                + where + """

                   order by lower(u.email) nulls last, u.id
                  offset :offset limit :limit)
                select page.id, page.email, page.created_at, p.tenant_id, t.name, t.slug, t.status, p.id,
                       p.given_name, p.family_name, p.active,
                       (select string_agg(r.role, ',') from core.membership_role r where r.person_id = p.id)
                  from page
                  left join core.person p on p.user_id = page.id
                  left join core.tenant t on t.id = p.tenant_id
                 order by lower(page.email) nulls last, page.id, lower(t.name), t.id""")
                .setParameter("offset", page.offset())
                .setParameter("limit", page.size());
        pattern.ifPresent(q -> {
            count.setParameter("q", q);
            items.setParameter("q", q);
        });
        long total = ((Number) count.getSingleResult()).longValue();
        return new PageResult<>(logins(items.getResultList()), page, total);
    }

    /** {@code %text%} lower-cased, with LIKE's own characters taken literally. */
    static String containsPattern(String text) {
        return "%" + text.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
                + "%";
    }

    /** One row per (login, person); a login without persons has one row of nulls after its own columns. */
    private static List<Login> logins(List<?> rows) {
        Map<UUID, Object[]> logins = new LinkedHashMap<>();
        Map<UUID, List<Membership>> memberships = new HashMap<>();
        for (Object item : rows) {
            Object[] row = (Object[]) item;
            UUID login = (UUID) row[0];
            logins.putIfAbsent(login, row);
            List<Membership> own = memberships.computeIfAbsent(login, key -> new ArrayList<>());
            if (row[3] != null) {
                own.add(new Membership(new TenantId((UUID) row[3]), (String) row[4], (String) row[5],
                        TenantStatus.valueOf((String) row[6]), new PersonId((UUID) row[7]), (String) row[8],
                        (String) row[9], roles((String) row[11]), (Boolean) row[10]));
            }
        }
        return logins.entrySet().stream().map(login -> new Login(new UserId(login.getKey()),
                Optional.ofNullable((String) login.getValue()[1]), instant(login.getValue()[2]),
                memberships.get(login.getKey()))).toList();
    }

    private static Set<TenantRole> roles(String names) {
        Set<TenantRole> roles = EnumSet.noneOf(TenantRole.class);
        if (names != null) {
            Arrays.stream(names.split(",")).map(TenantRole::valueOf).forEach(roles::add);
        }
        return roles;
    }

    private static Instant instant(Object value) {
        return switch (value) {
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case java.sql.Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("unexpected timestamp type " + value.getClass());
        };
    }
}
