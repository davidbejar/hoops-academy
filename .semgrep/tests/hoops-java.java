// Fixtures for `semgrep --test --config .semgrep/rules .semgrep/tests` (never compiled).
package fixtures;

import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.persistence.EntityManager;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

// ruleid: hoops-permitall-on-api-resource
@PermitAll
@Path("/api/core/players")
class OpenTenantResource {
    @GET
    public String list() { return "[]"; }
}

@Path("/platform/tenants")
class PlatformResource {
    // ruleid: hoops-permitall-on-api-resource
    @GET
    @PermitAll
    public String list() { return "[]"; }

    // ok: hoops-permitall-on-api-resource
    @RolesAllowed("super_admin")
    public String stats() { return "{}"; }
}

@Path("/internal/usage")
class InternalResource {
    // ruleid: hoops-permitall-on-api-resource
    @PermitAll
    public String usage() { return "{}"; }
}

@Path("/q/custom-health")
class HealthResource {
    // ok: hoops-permitall-on-api-resource
    @PermitAll
    public String ok() { return "ok"; }
}

class TenantBypass {
    // ok: hoops-no-tenant-check-bypass
    static final String NO_TENANT = "00000000-0000-0000-0000-000000000000";

    // ruleid: hoops-no-tenant-check-bypass
    boolean skipTenantCheck;

    // ruleid: hoops-no-tenant-check-bypass
    void bypassTenantFilter() {}

    void caller(Repo repo) {
        // ruleid: hoops-no-tenant-check-bypass
        repo.disableTenantIsolation();
        // ok: hoops-no-tenant-check-bypass
        repo.tenantScoped();
    }

    void rls(EntityManager em) {
        // ruleid: hoops-no-rls-bypass-sql
        em.createNativeQuery("set row_security = off").executeUpdate();
        // ruleid: hoops-no-rls-bypass-sql
        em.createNativeQuery("SET ROLE core_migrator").executeUpdate();
        // ok: hoops-no-rls-bypass-sql
        em.createNativeQuery("select 1").getSingleResult();
    }

    void tenantSwitch(EntityManager em, String tenant) {
        // ruleid: hoops-tenant-switch-outside-tenancy
        em.createNativeQuery("select set_config('app.tenant_id', :tenant, true)").setParameter("tenant", tenant);
        // ruleid: hoops-tenant-switch-outside-tenancy
        em.createNativeQuery("select set_config(:name, :value, true)");
        // ok: hoops-tenant-switch-outside-tenancy
        em.createNativeQuery("select current_setting('app.tenant_id', true)");
    }
}

class Queries {
    private static final String COLUMNS = "id, name";
    private final EntityManager em;
    private final java.sql.Connection connection;

    Queries(EntityManager em, java.sql.Connection connection) { this.em = em; this.connection = connection; }

    Object byName(String name) {
        // ruleid: hoops-sql-concat-from-parameter
        return em.createQuery("select p from Player p where p.name = '" + name + "'").getResultList();
    }

    Object nativeByName(String name) {
        String sql = "select * from core.player where name = '" + name + "'";
        // ruleid: hoops-sql-concat-from-parameter
        return em.createNativeQuery(sql).getResultList();
    }

    Object formatted(String order) throws java.sql.SQLException {
        // ruleid: hoops-sql-concat-from-parameter
        return connection.prepareStatement("select %s from t order by %s".formatted(COLUMNS, order));
    }

    Object jdbc(String filter) throws java.sql.SQLException {
        // ruleid: hoops-sql-concat-from-parameter
        return connection.createStatement().executeQuery(String.format("select * from t where %s", filter));
    }

    Object constants(java.util.UUID id) {
        // ok: hoops-sql-concat-from-parameter
        return em.createNativeQuery("select " + COLUMNS + " from core.player where id = :id").setParameter("id", id);
    }

    Object bound(String name) {
        // ok: hoops-sql-concat-from-parameter
        return em.createQuery("select p from Player p where p.name = :name").setParameter("name", name);
    }

    Object chosenFragment(boolean active) {
        String where = active ? " where p.active" : "";
        // ok: hoops-sql-concat-from-parameter
        return em.createQuery("select p from Player p" + where).getResultList();
    }
}

interface Repo {
    // ruleid: hoops-no-tenant-check-bypass
    void disableTenantIsolation();
    void tenantScoped();
}
