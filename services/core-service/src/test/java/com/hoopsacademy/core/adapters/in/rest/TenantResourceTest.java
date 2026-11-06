package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RecordingSettingsListener;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TenantResourceTest {

    private static final String PROFILE = "/api/core/tenant";
    private static final String SETTINGS = "/api/core/tenant/settings";

    @Inject
    RecordingSettingsListener settingsListener;

    private String tenant;

    @BeforeEach
    void freshTenant() {
        tenant = Members.newTenant();
    }

    @Test
    void anyMemberReadsTheProfileAndSettings() {
        Members.signIn(tenant, TenantRole.PLAYER);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(200)
                .body("id", equalTo(tenant))
                .body("timezone", equalTo("Europe/Madrid"))
                .body("defaultLocale", equalTo("es"))
                .body("hasLogo", equalTo(false))
                .body("logoEtag", nullValue());
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(SETTINGS).then().statusCode(200)
                .body("ageRule", equalTo("BIRTH_YEAR"))
                .body("maxPlayUpLevels", nullValue())
                .body("attendanceLateThresholdMinutes", equalTo(10));
    }

    @Test
    void adminEditsTheProfileAndClearsTheNamedFields() {
        Members.signIn(tenant, TenantRole.ADMIN);
        patchProfile("{\"name\":\"Hoops Bandung\",\"timezone\":\"Asia/Jakarta\",\"defaultLocale\":\"id\","
                + "\"contactEmail\":\"info@example.com\",\"websiteUrl\":\"https://hoops.example.com\"}")
                .statusCode(200)
                .body("name", equalTo("Hoops Bandung"))
                .body("timezone", equalTo("Asia/Jakarta"))
                .body("defaultLocale", equalTo("id"))
                .body("contactEmail", equalTo("info@example.com"));
        assertThat(CoreDb.auditRow(tenant, "tenant.profile_changed").get("metadata"))
                .contains("name", "timezone", "contactEmail").doesNotContain("info@example.com");
        patchProfile("{\"contactEmail\":null}").statusCode(200)
                .body("contactEmail", equalTo("info@example.com"));
        patchProfile("{\"clear\":[\"contactEmail\"]}").statusCode(200)
                .body("contactEmail", nullValue())
                .body("websiteUrl", equalTo("https://hoops.example.com"))
                .body("name", equalTo("Hoops Bandung"));
        assertThat(CoreDb.auditRow(tenant, "tenant.profile_changed").get("metadata")).contains("contactEmail")
                .doesNotContain("websiteUrl", "name");
    }

    @Test
    void aProfilePatchThatChangesNothingWritesNoAuditRow() {
        Members.signIn(tenant, TenantRole.ADMIN);
        patchProfile("{\"name\":\"Hoops Bandung\",\"websiteUrl\":\"https://hoops.example.com\"}").statusCode(200);
        int before = CoreDb.auditActions(tenant).size();

        patchProfile("{\"name\":\"Hoops Bandung\",\"timezone\":\"Europe/Madrid\",\"websiteUrl\":\"https://hoops.example.com\"}")
                .statusCode(200).body("name", equalTo("Hoops Bandung"));
        patchProfile("{\"clear\":[\"contactEmail\"]}").statusCode(200).body("contactEmail", nullValue());
        assertThat(CoreDb.auditActions(tenant)).as("nothing changed: no audit row").hasSize(before);

        patchProfile("{\"name\":\"Hoops Bandung\",\"timezone\":\"Asia/Jakarta\"}").statusCode(200);
        assertThat(CoreDb.auditActions(tenant)).hasSize(before + 1).last().isEqualTo("tenant.profile_changed");
        assertThat(CoreDb.auditRow(tenant, "tenant.profile_changed").get("metadata")).contains("timezone")
                .doesNotContain("name");
    }

    @Test
    void invalidProfilePatchesAreRejected() {
        Members.signIn(tenant, TenantRole.ADMIN);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{}").patch(PROFILE).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"name\":null}").patch(PROFILE).then().statusCode(400).body("violations.field", hasItem("name"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"clear\":[\"name\"]}").patch(PROFILE).then().statusCode(400)
                .body("violations.field", hasItem("clear"));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"websiteUrl\":\"https://x.example.com\",\"clear\":[\"websiteUrl\"]}").patch(PROFILE).then()
                .statusCode(400).body("violations.code", hasItem("CLEAR_CONFLICT"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"websiteUrl\":\"javascript:alert(1)\"}").patch(PROFILE).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"contactEmail\":\"not-an-email\"}").patch(PROFILE).then().statusCode(400);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"timezone\":\"Mars/Olympus\"}").patch(PROFILE).then().statusCode(422)
                .body("code", equalTo("INVALID_TIMEZONE"));
    }

    @Test
    void adminReplacesSettingsAndEligibilityListenersHearRuleChangesOnly() {
        Members.signIn(tenant, TenantRole.ADMIN);
        int before = settingsListener.calls();
        putSettings("{\"ageRule\":\"BIRTH_YEAR\",\"maxPlayUpLevels\":null,\"attendanceLateThresholdMinutes\":15}")
                .statusCode(200).body("attendanceLateThresholdMinutes", equalTo(15));
        assertThat(settingsListener.calls()).isEqualTo(before);
        assertThat(CoreDb.auditActions(tenant)).containsOnlyOnce("tenant.settings_changed");
        putSettings("{\"ageRule\":\"BIRTHDAY\",\"maxPlayUpLevels\":1}")
                .statusCode(200).body("ageRule", equalTo("BIRTHDAY")).body("maxPlayUpLevels", equalTo(1))
                .body("attendanceLateThresholdMinutes", equalTo(10));
        assertThat(settingsListener.calls()).isEqualTo(before + 1);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"ageRule\":\"BIRTHDAY\",\"maxPlayUpLevels\":-1}").put(SETTINGS).then().statusCode(400);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsWriteTheProfileAndSettings(Set<TenantRole> roles, boolean admin) {
        Members.signIn(tenant, roles);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(200);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(SETTINGS).then().statusCode(200);
        patchProfile("{\"name\":\"Matrix\"}").statusCode(admin ? 200 : 403);
        putSettings("{\"ageRule\":\"BIRTH_YEAR\",\"maxPlayUpLevels\":2}").statusCode(admin ? 200 : 403);
    }

    @Test
    void nonMembersGetNotFoundAndNeverSeeAnotherTenantsProfile() {
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(SETTINGS).then().statusCode(404);
        patchProfile("{\"name\":\"Hijack\"}").statusCode(404);
        putSettings("{\"ageRule\":\"BIRTHDAY\",\"maxPlayUpLevels\":0}").statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(PROFILE).then().statusCode(200)
                .body("id", equalTo(other));
    }

    @Test
    void missingOrMalformedTenantHeaderIsBadRequest() {
        Members.signIn(tenant, TenantRole.ADMIN);
        given().filter(Contract.RESPONSES_ONLY).get(PROFILE).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", "nope").get(PROFILE).then().statusCode(400)
                .body("instance", endsWith(PROFILE));
    }

    private io.restassured.response.ValidatableResponse patchProfile(String body) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(body)
                .patch(PROFILE).then();
    }

    private io.restassured.response.ValidatableResponse putSettings(String body) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(body)
                .put(SETTINGS).then();
    }
}
