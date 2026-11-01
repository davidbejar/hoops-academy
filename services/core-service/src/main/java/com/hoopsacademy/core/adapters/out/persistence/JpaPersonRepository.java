package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumSet;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/** Person aggregate = person row + its membership_role rows (tenant filter + RLS on both). */
@ApplicationScoped
class JpaPersonRepository implements PersonRepository {

    private final EntityManager em;

    JpaPersonRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(Person person) {
        PersonEntity row = new PersonEntity();
        row.id = person.id().value();
        row.createdAt = person.createdAt();
        copy(person, row);
        em.persist(row);
        person.roles().forEach(role -> em.persist(new MembershipRoleEntity(row.id, role.name())));
    }

    @Override
    public void update(Person person) {
        PersonEntity row = em.find(PersonEntity.class, person.id().value());
        copy(person, row);
        Set<TenantRole> stored = rolesOf(List.of(row.id)).getOrDefault(row.id, Set.of());
        stored.stream().filter(role -> !person.roles().contains(role)).forEach(role ->
                em.createQuery("delete from MembershipRoleEntity r where r.personId = :person and r.role = :role")
                        .setParameter("person", row.id).setParameter("role", role.name()).executeUpdate());
        person.roles().stream().filter(role -> !stored.contains(role))
                .forEach(role -> em.persist(new MembershipRoleEntity(row.id, role.name())));
    }

    @Override
    public Optional<Person> find(PersonId id) {
        return findAll(List.of(id)).stream().findFirst();
    }

    @Override
    public List<Person> findAll(Collection<PersonId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        return toDomain(em.createQuery("select p from PersonEntity p where p.id in :ids", PersonEntity.class)
                .setParameter("ids", ids.stream().map(PersonId::value).toList()).getResultList());
    }

    @Override
    public Optional<Person> findActiveByLogin(String subject) {
        return toDomain(em.createQuery("""
                select p from PersonEntity p
                 where p.active = true
                   and p.userId = (select u.id from AppUserEntity u where u.keycloakSub = :sub)""", PersonEntity.class)
                .setParameter("sub", subject).getResultList()).stream().findFirst();
    }

    @Override
    public boolean emailTaken(String email, Optional<PersonId> except) {
        return em.createQuery("select p.id from PersonEntity p where lower(p.email) = :email", UUID.class)
                .setParameter("email", email.toLowerCase(Locale.ROOT))
                .getResultStream()
                .anyMatch(id -> except.map(PersonId::value).filter(id::equals).isEmpty());
    }

    @Override
    public boolean loginLinked(UserId user) {
        return em.createQuery("select count(p) from PersonEntity p where p.userId = :user", Long.class)
                .setParameter("user", user.value()).getSingleResult() > 0;
    }

    @Override
    public long countActiveAdmins() {
        return em.createQuery("""
                select count(r) from MembershipRoleEntity r, PersonEntity p
                 where p.id = r.personId and p.active = true and r.role = 'ADMIN'""", Long.class).getSingleResult();
    }

    @Override
    public long countActive() {
        return em.createQuery("select count(p) from PersonEntity p where p.active = true", Long.class)
                .getSingleResult();
    }

    @Override
    public Map<TenantRole, Long> countActiveByRole() {
        Map<TenantRole, Long> counts = new EnumMap<>(TenantRole.class);
        em.createQuery("""
                        select r.role, count(r) from MembershipRoleEntity r, PersonEntity p
                         where p.id = r.personId and p.active = true group by r.role""", Object[].class)
                .getResultList().forEach(row -> counts.put(TenantRole.valueOf((String) row[0]), (Long) row[1]));
        return counts;
    }

    @Override
    public PageResult<Person> list(MemberFilter filter, PageRequest page) {
        List<String> conditions = new ArrayList<>();
        Map<String, Object> parameters = new HashMap<>();
        // players awaiting approval or rejected are not members yet (WP5 follow-up); they live in /approval-requests
        conditions.add("not exists (select 1 from PlayerEntity pl where pl.personId = p.id"
                + " and pl.status in ('PENDING_APPROVAL', 'REJECTED'))");
        filter.role().ifPresent(role -> {
            conditions.add("exists (select 1 from MembershipRoleEntity r where r.personId = p.id and r.role = :role)");
            parameters.put("role", role.name());
        });
        filter.active().ifPresent(active -> {
            conditions.add("p.active = :active");
            parameters.put("active", active);
        });
        filter.query().map(JpaPersonRepository::likePattern).ifPresent(pattern -> {
            conditions.add("(lower(p.givenName) like :q escape '\\' or lower(p.familyName) like :q escape '\\'"
                    + " or lower(p.email) like :q escape '\\')");
            parameters.put("q", pattern);
        });
        String where = " where " + String.join(" and ", conditions);
        TypedQuery<PersonEntity> items = em.createQuery(
                "select p from PersonEntity p" + where + " order by lower(p.familyName), lower(p.givenName), p.id",
                PersonEntity.class);
        TypedQuery<Long> total = em.createQuery("select count(p) from PersonEntity p" + where, Long.class);
        parameters.forEach((name, value) -> {
            items.setParameter(name, value);
            total.setParameter(name, value);
        });
        List<PersonEntity> rows = items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultList();
        return new PageResult<>(toDomain(rows), page, total.getSingleResult());
    }

    private static String likePattern(String query) {
        String escaped = query.toLowerCase(Locale.ROOT).replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        return "%" + escaped + "%";
    }

    private List<Person> toDomain(List<PersonEntity> rows) {
        Map<UUID, Set<TenantRole>> roles = rolesOf(rows.stream().map(row -> row.id).toList());
        return rows.stream().map(row -> toDomain(row, roles.getOrDefault(row.id, Set.of()))).toList();
    }

    private Map<UUID, Set<TenantRole>> rolesOf(List<UUID> personIds) {
        if (personIds.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("select r from MembershipRoleEntity r where r.personId in :ids", MembershipRoleEntity.class)
                .setParameter("ids", personIds).getResultStream()
                .collect(Collectors.groupingBy(r -> r.personId,
                        Collectors.mapping(r -> TenantRole.valueOf(r.role),
                                Collectors.toCollection(() -> EnumSet.noneOf(TenantRole.class)))));
    }

    private static Person toDomain(PersonEntity row, Set<TenantRole> roles) {
        PersonalData data = new PersonalData(row.givenName, row.familyName, row.email, row.phone, row.birthDate,
                row.gender == null ? null : Gender.valueOf(row.gender),
                row.locale == null ? null : AppLocale.fromCode(row.locale));
        return new Person(new PersonId(row.id), row.userId == null ? null : new UserId(row.userId), data,
                new HashSet<>(roles), row.active, InvitationStatus.valueOf(row.invitationStatus), row.createdAt,
                row.deactivatedAt);
    }

    private static void copy(Person person, PersonEntity row) {
        PersonalData data = person.data();
        row.userId = person.userId() == null ? null : person.userId().value();
        row.givenName = data.givenName();
        row.familyName = data.familyName();
        row.email = data.email();
        row.phone = data.phone();
        row.birthDate = data.birthDate();
        row.gender = data.gender() == null ? null : data.gender().name();
        row.locale = data.locale() == null ? null : data.locale().code();
        row.active = person.active();
        row.invitationStatus = person.invitationStatus().name();
        row.deactivatedAt = person.deactivatedAt();
    }
}
