package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.AuditNames;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Names for the audit trail as core_app in the bound tenant: RLS hides other tenants' rows, so a forged or foreign id
 * resolves to nothing. Names follow {@code PersonalData.displayName()} (given and family name).
 */
@ApplicationScoped
class JpaAuditNameRepository implements AuditNames {

    private final EntityManager em;

    JpaAuditNameRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Map<UUID, String> persons(Set<UUID> ids) {
        return names("select p.id, p.given_name || ' ' || p.family_name from core.person p where p.id in (:ids)", ids);
    }

    @Override
    public Map<UUID, String> players(Set<UUID> ids) {
        return names("""
                select pl.id, p.given_name || ' ' || p.family_name
                  from core.player pl join core.person p on p.id = pl.person_id
                 where pl.id in (:ids)""", ids);
    }

    @Override
    public Map<UUID, String> tenants(Set<UUID> ids) {
        return names("select t.id, t.name from core.tenant t where t.id in (:ids)", ids);
    }

    @Override
    public Map<UUID, String> activeAdmins(Set<UUID> ids) {
        return names("""
                select p.id, p.given_name || ' ' || p.family_name from core.person p
                 where p.id in (:ids) and p.active
                   and exists (select 1 from core.membership_role r where r.person_id = p.id and r.role = 'ADMIN')""",
                ids);
    }

    private Map<UUID, String> names(String sql, Set<UUID> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql, Object[].class).setParameter("ids", ids).getResultList();
        Map<UUID, String> names = new HashMap<>();
        rows.forEach(row -> names.put((UUID) row[0], (String) row[1]));
        return names;
    }
}
