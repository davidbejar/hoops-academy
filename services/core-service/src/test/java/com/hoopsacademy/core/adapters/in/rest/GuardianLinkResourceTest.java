package com.hoopsacademy.core.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.Members;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@CoreTestResources
@TestSecurity(user = TenantUser.SUBJECT)
class GuardianLinkResourceTest {

    private static final String LINKS = "/api/core/guardian-links";

    private String tenant;
    private UUID parent;
    private UUID player;

    @BeforeEach
    void parentAndPlayer() {
        tenant = Members.newTenant();
        parent = CoreDb.person(tenant, "Pia", "Parent", null, TenantRole.PARENT);
        UUID kidPerson = CoreDb.person(tenant, null, "Kai", "Kid", null, LocalDate.of(2015, 6, 1), "MALE",
                TenantRole.PLAYER);
        player = CoreDb.player(tenant, kidPerson);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void adminLinksListsAndUnlinks() {
        var created = create(parent, player).statusCode(201)
                .body("guardian.personId", equalTo(parent.toString()))
                .body("guardian.displayName", equalTo("Pia Parent"))
                .body("player.id", equalTo(player.toString()))
                .body("player.displayName", equalTo("Kai Kid"))
                .extract();
        String id = created.path("id");
        assertThat(created.header("Location")).endsWith(LINKS + "/" + id);

        Contract.forTenant(tenant).queryParam("playerId", player.toString())
                .get(LINKS).then().statusCode(200).body("items.id", contains(id)).body("page.totalElements", equalTo(1));
        Contract.forTenant(tenant).queryParam("guardianPersonId", UUID.randomUUID().toString())
                .get(LINKS).then().statusCode(200).body("items", hasSize(0));
        delete(UUID.fromString(id)).statusCode(204);
        delete(UUID.fromString(id)).statusCode(404);
        assertThat(CoreDb.auditActions(tenant)).containsSubsequence("guardian_link.created", "guardian_link.removed");
        assertThat(CoreDb.auditRow(tenant, "guardian_link.removed")).containsEntry("targetId", id);
    }

    @Test
    void guardianMustBeAParentAndLinksAreUnique() {
        UUID coach = CoreDb.person(tenant, "Cole", "Coach", null, TenantRole.COACH);
        create(coach, player).statusCode(422).body("code", equalTo("GUARDIAN_NOT_PARENT"));
        create(parent, player).statusCode(201);
        create(parent, player).statusCode(409);
        create(parent, UUID.randomUUID()).statusCode(404);
        create(UUID.randomUUID(), player).statusCode(404);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsManageGuardianLinks(Set<TenantRole> roles, boolean admin) {
        UUID existing = CoreDb.guardianLink(tenant, parent, player);
        Members.signIn(tenant, roles);
        int expected = admin ? 200 : 403;
        Contract.forTenant(tenant).get(LINKS).then().statusCode(expected);
        delete(existing).statusCode(admin ? 204 : 403);
        create(parent, player).statusCode(admin ? 201 : 403);
    }

    @Test
    void anotherTenantsLinksAreNotFound() {
        UUID foreignLink = CoreDb.guardianLink(tenant, parent, player);
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        Contract.forTenant(other).delete(LINKS + "/" + foreignLink).then().statusCode(404);
        Contract.forTenant(other).contentType(ContentType.JSON)
                .body("{\"guardianPersonId\":\"" + parent + "\",\"playerId\":\"" + player + "\"}")
                .post(LINKS).then().statusCode(404);
        Contract.forTenant(other).get(LINKS).then().statusCode(200).body("items", hasSize(0));
        Contract.forTenant(tenant).get(LINKS).then().statusCode(404);
        assertThat(CoreDb.count(tenant, "select count(*) from core.guardian_link where id = ?", foreignLink)).isEqualTo(1);
    }

    private ValidatableResponse create(UUID guardian, UUID playerId) {
        return Contract.forTenant(tenant).contentType(ContentType.JSON)
                .body("{\"guardianPersonId\":\"" + guardian + "\",\"playerId\":\"" + playerId + "\"}")
                .post(LINKS).then();
    }

    private ValidatableResponse delete(UUID id) {
        return Contract.forTenant(tenant).delete(LINKS + "/" + id).then();
    }
}
