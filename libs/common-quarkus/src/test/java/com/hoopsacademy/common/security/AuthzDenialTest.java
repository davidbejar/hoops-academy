package com.hoopsacademy.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class AuthzDenialTest {

    private static final String TENANT = "0a000000-0000-4000-8000-00000000000a";

    @ParameterizedTest
    @CsvSource({
        "UNAUTHENTICATED, unauthenticated, 401",
        "INVALID_TOKEN, invalid_token, 401",
        "NOT_MEMBER, not_member, 404",
        "TENANT_MISMATCH, tenant_mismatch, 404",
        "ROLE, role, 403",
        "FINE_GRAINED, fine_grained, 403",
        "REALM_ROLE, realm_role, 403"})
    void eachKindHasAWireNameAndTheStatusTheCallerGot(DenialKind kind, String wireName, int status) {
        assertThat(kind.wireName()).isEqualTo(wireName);
        assertThat(kind.status()).isEqualTo(status);
    }

    @Test
    void theFieldsNameEveryAspectOfTheDenialInAFixedOrder() {
        AuthzDenial denial = new AuthzDenial(DenialKind.ROLE, TENANT, "sub-1", Set.of("PARENT", "COACH"),
                "GET /api/probe/authz/staff-area", "Requires one of [ADMIN]");

        assertThat(denial.fields()).containsExactly(
                entry("security.event", "authz_denied"),
                entry("security.kind", "role"),
                entry("security.outcome", "403"),
                entry("tenantId", TENANT),
                entry("security.subject", "sub-1"),
                entry("security.roles", "COACH,PARENT"),
                entry("security.resource", "GET /api/probe/authz/staff-area"),
                entry("security.reason", "Requires one of [ADMIN]"));
    }

    @Test
    void theMessageRepeatsTheFieldsForPlainTextReaders() {
        AuthzDenial denial = new AuthzDenial(DenialKind.NOT_MEMBER, TENANT, "sub-1", Set.of(), "GET /api/x", null);

        assertThat(denial.message()).isEqualTo("authz_denied kind=not_member outcome=404 tenant=" + TENANT
                + " subject=sub-1 roles=- resource=\"GET /api/x\" reason=\"-\"");
    }

    @Test
    void unknownValuesAreADash() {
        AuthzDenial denial = new AuthzDenial(DenialKind.INVALID_TOKEN, null, " ", null, null, "");

        assertThat(denial.fields())
                .containsEntry("tenantId", "-")
                .containsEntry("security.subject", "-")
                .containsEntry("security.roles", "-")
                .containsEntry("security.resource", "-")
                .containsEntry("security.reason", "-");
    }

    @Test
    void controlCharactersAndQuotesNeverReachTheLogLine() {
        AuthzDenial denial = new AuthzDenial(DenialKind.FINE_GRAINED, TENANT, "sub\r\nkind=forged",
                Set.of("COACH\n"), "GET /api/x\u0000\u001b[31m", "say \"hi\"\tthere");

        assertThat(denial.fields().values()).allSatisfy(value -> assertThat(value).doesNotContainPattern("[\\p{Cntrl}\"]"));
        assertThat(denial.fields().get("security.subject")).isEqualTo("sub__kind=forged");
        assertThat(denial.fields().get("security.reason")).isEqualTo("say 'hi'_there");
        assertThat(denial.message()).doesNotContain("\n").doesNotContain("\r");
    }

    @Test
    void longValuesAreCut() {
        AuthzDenial denial = new AuthzDenial(DenialKind.FINE_GRAINED, TENANT, "s", Set.of(), "GET /" + "a".repeat(500),
                "r".repeat(500));

        assertThat(denial.fields().get("security.resource")).hasSize(AuthzDenial.MAX_VALUE_LENGTH);
        assertThat(denial.fields().get("security.reason")).hasSize(AuthzDenial.MAX_VALUE_LENGTH).endsWith("...");
    }

    @Test
    void aValueOfTheMaximumLengthIsKeptWhole() {
        String exact = "r".repeat(AuthzDenial.MAX_VALUE_LENGTH);

        assertThat(new AuthzDenial(DenialKind.ROLE, TENANT, "s", Set.of(), "r", exact).fields().get("security.reason"))
                .isEqualTo(exact);
    }

    @Test
    void aKindIsRequired() {
        assertThatThrownBy(() -> new AuthzDenial(null, TENANT, "s", Set.of(), "r", "x"))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    void theFieldKeysAreTheOnesTheEventDeclares() {
        assertThat(new AuthzDenial(DenialKind.ROLE, TENANT, "s", Set.of(), "r", "x").fields().keySet())
                .containsExactlyElementsOf(AuthzDenial.FIELD_KEYS);
        assertThat(AuthzDenial.FIELD_KEYS).doesNotHaveDuplicates().hasSize(8);
    }

    private static java.util.Map.Entry<String, String> entry(String key, String value) {
        return java.util.Map.entry(key, value);
    }
}
