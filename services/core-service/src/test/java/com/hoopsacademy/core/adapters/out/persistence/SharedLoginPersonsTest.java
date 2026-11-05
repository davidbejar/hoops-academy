package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.SharedLoginPersons;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.Patch;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * The super admin's login e-mail move reaches the person rows of other tenants that share the login (WP31,
 * ADR-0026): inside the home tenant's transaction, as core_app, binding {@code app.tenant_id} to the other tenant for
 * its own statements only — RLS in force there, and the home binding restored afterwards.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class SharedLoginPersonsTest {

    @Inject
    SharedLoginPersons shared;

    @Inject
    MembershipRepository memberships;

    @Inject
    PersonRepository persons;

    @Inject
    TenantScope tenantScope;

    @Inject
    EntityManager em;

    private String home;
    private String other;
    private String sub;
    private UUID login;
    private UUID homePerson;
    private UUID linked;
    private UUID bystander;

    @BeforeEach
    void loginSharedByTwoTenants() {
        home = Members.newTenant();
        other = Members.newTenant();
        sub = "shared-" + UUID.randomUUID();
        login = CoreDb.appUser(sub, "old@example.com");
        homePerson = CoreDb.person(home, login, "Ho", "Me", "old@example.com", null, null, TenantRole.ADMIN);
        linked = CoreDb.person(other, login, "Ho", "Me", "old@example.com", null, null, TenantRole.PARENT);
        bystander = CoreDb.person(other, "By", "Stander", "by@example.com", TenantRole.COACH);
    }

    @Test
    void theOtherTenantsActiveLinksOfTheLoginAreListed() {
        String left = Members.newTenant();
        UUID former = CoreDb.person(left, login, "Ho", "Me", null, null, null, TenantRole.PARENT);
        CoreDb.inTenant(left, c -> CoreDb.update(c, "delete from core.user_membership_index where person_id = ?", former));

        List<IndexedMembership> links = inHome(() -> memberships.inOtherTenants(sub));

        assertThat(links).containsExactly(new IndexedMembership(TenantId.parse(other), new PersonId(linked)));
        assertThat(inHome(() -> memberships.inOtherTenants("unknown-" + UUID.randomUUID()))).isEmpty();
    }

    @Test
    void listingRestoresTheSubjectSoOtherTenantsStayInvisible() {
        Object[] after = inHome(() -> {
            memberships.inOtherTenants(sub);
            return (Object[]) em.createNativeQuery("""
                    select coalesce(current_setting('app.subject', true), ''),
                           (select count(*) from core.user_membership_index where keycloak_sub = :sub)""")
                    .setParameter("sub", sub).getSingleResult();
        });
        assertThat(after[0]).isEqualTo("");
        assertThat(((Number) after[1]).longValue()).as("own tenant's row only").isEqualTo(1);
    }

    @Test
    void theLinkedPersonGetsTheEmailAndTheOtherTenantAnAuditRow() {
        boolean changed = inHome(() -> shared.changeEmail(link(linked), new UserId(login), "new@example.com",
                AuditEvent.of("member.login_email_changed", "person", linked)));

        assertThat(changed).isTrue();
        assertThat(emailOf(other, linked)).isEqualTo("new@example.com");
        assertThat(emailOf(other, bystander)).isEqualTo("by@example.com");
        assertThat(CoreDb.auditActions(other)).containsExactly("member.login_email_changed");
        assertThat(CoreDb.auditRow(other, "member.login_email_changed")).containsEntry("targetId", linked.toString())
                .containsEntry("actorPersonId", null);
        assertThat(CoreDb.auditActions(home)).isEmpty();
    }

    @Test
    void aPersonThatDoesNotLinkTheLoginIsNeverChanged() {
        boolean changed = inHome(() -> shared.changeEmail(link(bystander), new UserId(login), "new@example.com",
                AuditEvent.of("member.login_email_changed", "person", bystander)));

        assertThat(changed).isFalse();
        assertThat(emailOf(other, bystander)).isEqualTo("by@example.com");
        assertThat(CoreDb.auditActions(other)).isEmpty();
    }

    @Test
    void anEmailIsTakenOnlyByAnotherPersonOfThatTenant() {
        assertThat(inHome(() -> shared.emailTaken(link(linked), "BY@example.com"))).isTrue();
        assertThat(inHome(() -> shared.emailTaken(link(linked), "old@example.com"))).as("the linked person itself")
                .isFalse();
        assertThat(inHome(() -> shared.emailTaken(link(linked), "free@example.com"))).isFalse();
    }

    @Test
    void theHomeBindingIsRestoredAndItsPendingWritesKeepTheirTenant() {
        Object[] after = inHome(() -> {
            persons.update(persons.find(new PersonId(homePerson)).orElseThrow()
                    .withData(PersonalDataChanges.none().withGivenName(Patch.of("Renamed"))));
            shared.changeEmail(link(linked), new UserId(login), "new@example.com",
                    AuditEvent.of("member.login_email_changed", "person", linked));
            return (Object[]) em.createNativeQuery("""
                    select current_setting('app.tenant_id', true), (select count(*) from core.person)""")
                    .getSingleResult();
        });

        assertThat(after[0]).isEqualTo(home);
        assertThat(((Number) after[1]).longValue()).as("only the home tenant's people are visible again").isEqualTo(1);
        assertThat(RosterDb.text(home, "select given_name from core.person where id = ?", homePerson))
                .isEqualTo("Renamed");
    }

    @Test
    void theBoundTenantItselfIsNotAnotherTenant() {
        IndexedMembership self = new IndexedMembership(TenantId.parse(home), new PersonId(homePerson));
        assertThatThrownBy(() -> inHome(() -> shared.emailTaken(self, "x@example.com")))
                .isInstanceOf(IllegalArgumentException.class);
    }

    private IndexedMembership link(UUID person) {
        return new IndexedMembership(TenantId.parse(other), new PersonId(person));
    }

    private <T> T inHome(java.util.function.Supplier<T> work) {
        return tenantScope.runAs(TenantId.parse(home), work);
    }

    private static String emailOf(String tenant, UUID person) {
        return RosterDb.text(tenant, "select email from core.person where id = ?", person);
    }
}
