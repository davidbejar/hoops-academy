package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.matchesPattern;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.domain.logo.LogoImage;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.ValidatableResponse;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TenantLogoResourceTest {

    private static final String LOGO = "/api/core/tenant/logo";
    static final byte[] PNG = bytes(0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 'I', 'H', 'D', 'R');
    static final byte[] JPEG = bytes(0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 'J', 'F', 'I', 'F', 0);
    static final byte[] WEBP = bytes('R', 'I', 'F', 'F', 0x24, 0, 0, 0, 'W', 'E', 'B', 'P', 'V', 'P', '8', ' ');
    static final byte[] GIF = "GIF89a\u0001\u0000\u0001\u0000".getBytes(StandardCharsets.ISO_8859_1);
    static final byte[] SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" onload=\"alert(1)\"/>".getBytes(StandardCharsets.UTF_8);

    private String tenant;

    @BeforeEach
    void freshTenant() {
        tenant = Members.newTenant();
    }

    @ParameterizedTest
    @CsvSource({"PNG, image/png", "JPEG, image/jpeg", "WEBP, image/webp"})
    void adminUploadsPngJpegOrWebp(String format, String mediaType) {
        Members.signIn(tenant, TenantRole.ADMIN);
        byte[] content = sample(format);
        put(content, mediaType).statusCode(200)
                .header("ETag", matchesPattern("\"[0-9a-f]{64}\""))
                .body("contentType", equalTo(mediaType))
                .body("sizeBytes", equalTo(content.length));
        byte[] served = given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(200)
                .contentType(mediaType)
                .header("Cache-Control", "private, max-age=86400")
                .header("X-Content-Type-Options", "nosniff")
                .extract().asByteArray();
        assertThat(served).isEqualTo(content);
    }

    @Test
    void theStoredTypeComesFromTheMagicBytesNotFromTheDeclaredType() {
        Members.signIn(tenant, TenantRole.ADMIN);
        put(JPEG, "image/png").statusCode(200).body("contentType", equalTo("image/jpeg"));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(200)
                .contentType("image/jpeg");
    }

    @Test
    void svgGifAndUnknownTypesAreUnsupported() {
        Members.signIn(tenant, TenantRole.ADMIN);
        putInvalid(SVG, "image/png").statusCode(415).body("code", equalTo("UNSUPPORTED_IMAGE_FORMAT"));
        putInvalid(GIF, "image/png").statusCode(415);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType("image/svg+xml").body(SVG)
                .put(LOGO).then().statusCode(415).contentType("application/problem+json");
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType("image/gif").body(GIF)
                .put(LOGO).then().statusCode(415);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(404);
    }

    @Test
    void sizeLimitIs512Kilobytes() {
        Members.signIn(tenant, TenantRole.ADMIN);
        putInvalid(Arrays.copyOf(PNG, LogoImage.MAX_BYTES + 1), "image/png").statusCode(413)
                .contentType("application/problem+json").body("code", equalTo("LOGO_TOO_LARGE"));
        put(Arrays.copyOf(PNG, LogoImage.MAX_BYTES), "image/png").statusCode(200).body("sizeBytes", equalTo(524_288));
    }

    @Test
    void conditionalGetAnswersNotModified() {
        Members.signIn(tenant, TenantRole.ADMIN);
        String etag = put(PNG, "image/png").extract().header("ETag");
        Members.signIn(tenant, TenantRole.PARENT);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).header("If-None-Match", etag).get(LOGO)
                .then().statusCode(304).header("ETag", etag);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).header("If-None-Match", "W/" + etag).get(LOGO)
                .then().statusCode(304);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).header("If-None-Match", "\"stale\"").get(LOGO)
                .then().statusCode(200);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get("/api/core/tenant").then().statusCode(200)
                .body("hasLogo", equalTo(true)).body("logoEtag", equalTo(etag));
    }

    @Test
    void adminDeletesTheLogo() {
        Members.signIn(tenant, TenantRole.ADMIN);
        put(WEBP, "image/webp").statusCode(200);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).delete(LOGO).then().statusCode(204);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).delete(LOGO).then().statusCode(404);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void everyMemberReadsOnlyAdminsWrite(Set<TenantRole> roles, boolean admin) {
        Members.signIn(tenant, TenantRole.ADMIN);
        put(PNG, "image/png").statusCode(200);
        Members.signIn(tenant, roles);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(200);
        put(JPEG, "image/jpeg").statusCode(admin ? 200 : 403);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).delete(LOGO).then().statusCode(admin ? 204 : 403);
    }

    @Test
    void anotherTenantsLogoIsNotFound() {
        Members.signIn(tenant, TenantRole.ADMIN);
        put(PNG, "image/png").statusCode(200);
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).delete(LOGO).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(LOGO).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).delete(LOGO).then().statusCode(404);
        Members.signIn(tenant, TenantRole.PARENT);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(LOGO).then().statusCode(200);
    }

    private ValidatableResponse put(byte[] content, String mediaType) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(mediaType)
                .body(content).put(LOGO).then();
    }

    /** For bodies the contract forbids (wrong format, oversize): only the response is validated. */
    private ValidatableResponse putInvalid(byte[] content, String mediaType) {
        return given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(mediaType)
                .body(content).put(LOGO).then();
    }

    private static byte[] sample(String format) {
        return switch (format) {
            case "PNG" -> PNG;
            case "JPEG" -> JPEG;
            default -> WEBP;
        };
    }

    private static byte[] bytes(int... values) {
        byte[] result = new byte[values.length];
        for (int i = 0; i < values.length; i++) {
            result[i] = (byte) values[i];
        }
        return result;
    }
}
