package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
class JpaAppUserRepository implements AppUserRepository {

    private final EntityManager em;

    JpaAppUserRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<AppUser> findBySubject(String subject) {
        return em.createQuery("select u from AppUserEntity u where u.keycloakSub = :sub", AppUserEntity.class)
                .setParameter("sub", subject)
                .getResultStream().findFirst().map(JpaAppUserRepository::toDomain);
    }

    @Override
    public Optional<AppUser> findById(UserId id) {
        return Optional.ofNullable(em.find(AppUserEntity.class, id.value())).map(JpaAppUserRepository::toDomain);
    }

    /** Insert-if-absent keyed by the unique subject, safe against concurrent first logins. */
    @Override
    public AppUser findOrRegister(String subject, String email) {
        em.createNativeQuery("""
                insert into core.app_user (id, keycloak_sub, email) values (:id, :sub, :email)
                on conflict (keycloak_sub) do nothing""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("sub", subject)
                .setParameter("email", email)
                .executeUpdate();
        return findBySubject(subject).orElseThrow();
    }

    @Override
    public void save(AppUser user) {
        AppUserEntity row = em.find(AppUserEntity.class, user.id().value());
        row.email = user.email();
        row.locale = user.locale() == null ? null : user.locale().code();
    }

    private static AppUser toDomain(AppUserEntity row) {
        return new AppUser(new UserId(row.id), row.keycloakSub, row.email,
                row.locale == null ? null : AppLocale.fromCode(row.locale));
    }
}
