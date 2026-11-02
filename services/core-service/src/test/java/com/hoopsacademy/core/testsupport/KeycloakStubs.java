package com.hoopsacademy.core.testsupport;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.delete;
import static com.github.tomakehurst.wiremock.client.WireMock.deleteRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.matching;
import static com.github.tomakehurst.wiremock.client.WireMock.matchingJsonPath;
import static com.github.tomakehurst.wiremock.client.WireMock.okJson;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.put;
import static com.github.tomakehurst.wiremock.client.WireMock.putRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.matching.RequestPatternBuilder;

/** Keycloak Admin API stubs (realm {@code academy}) used by the identity-provider tests. */
public final class KeycloakStubs {

    public static final String USERS = "/auth/admin/realms/academy/users";
    private static final String TOKEN = "/auth/realms/academy/protocol/openid-connect/token";
    private static final String TOKEN_BODY =
            "{\"access_token\":\"test-admin-token\",\"token_type\":\"Bearer\",\"expires_in\":300}";

    private KeycloakStubs() {}

    /**
     * Token endpoint, "no user with that e-mail", create → 201 with a fresh id, reset-password, update and delete →
     * 204, every user without credentials or required actions. No execute-actions e-mail is stubbed: a call to it
     * fails (ADR-0024, no e-mail is sent).
     */
    public static void installDefaults(WireMockServer server) {
        server.resetAll();
        server.stubFor(post(urlEqualTo(TOKEN)).willReturn(okJson(TOKEN_BODY)));
        server.stubFor(get(urlPathEqualTo(USERS)).willReturn(okJson("[]")));
        server.stubFor(post(urlEqualTo(USERS)).willReturn(aResponse().withStatus(201)
                .withHeader("Location", server.baseUrl() + USERS + "/{{randomValue type='UUID'}}")));
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+/reset-password")).willReturn(aResponse().withStatus(204)));
        server.stubFor(get(urlPathMatching(USERS + "/[^/]+/credentials")).willReturn(okJson("[]")));
        server.stubFor(get(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(200)
                .withHeader("Content-Type", "application/json")
                .withBody("{\"id\":\"{{request.path.[5]}}\",\"enabled\":true,\"requiredActions\":[]}")));
        server.stubFor(delete(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(204)));
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(204)));
        UsageStubs.installDefaults(server);
    }

    /** The next created user gets {@code subject} as id. */
    public static void createdUserGets(WireMockServer server, String subject) {
        server.stubFor(post(urlEqualTo(USERS)).willReturn(aResponse().withStatus(201)
                .withHeader("Location", server.baseUrl() + USERS + "/" + subject)));
    }

    /** A Keycloak user with this e-mail already exists. */
    public static void existingUser(WireMockServer server, String email, String subject) {
        server.stubFor(get(urlPathEqualTo(USERS)).withQueryParam("email", equalTo(email))
                .willReturn(okJson("[{\"id\":\"" + subject + "\",\"email\":\"" + email + "\",\"enabled\":true}]")));
    }

    /** The Keycloak user {@code subject} (read before a login update). */
    public static void login(WireMockServer server, String subject, String email) {
        server.stubFor(get(urlPathEqualTo(USERS + "/" + subject)).willReturn(okJson("""
                {"id":"%s","username":"%s","email":"%s","firstName":"Old","lastName":"Name","enabled":true,
                 "emailVerified":true}""".formatted(subject, email, email))));
    }

    /** The login {@code subject} has a password of its own (a password credential, no pending UPDATE_PASSWORD). */
    public static void ownPassword(WireMockServer server, String subject) {
        server.stubFor(get(urlPathEqualTo(USERS + "/" + subject + "/credentials"))
                .willReturn(okJson("[{\"id\":\"c1\",\"type\":\"password\"}]")));
        server.stubFor(get(urlPathEqualTo(USERS + "/" + subject))
                .willReturn(okJson("{\"id\":\"" + subject + "\",\"enabled\":true,\"requiredActions\":[]}")));
    }

    /** The login {@code subject} holds a temporary password (a password credential and UPDATE_PASSWORD pending). */
    public static void temporaryPassword(WireMockServer server, String subject) {
        server.stubFor(get(urlPathEqualTo(USERS + "/" + subject + "/credentials"))
                .willReturn(okJson("[{\"id\":\"c1\",\"type\":\"password\"}]")));
        server.stubFor(get(urlPathEqualTo(USERS + "/" + subject)).willReturn(okJson(
                "{\"id\":\"" + subject + "\",\"enabled\":true,\"requiredActions\":[\"UPDATE_PASSWORD\"]}")));
    }

    public static void temporaryPasswordFails(WireMockServer server) {
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+/reset-password")).willReturn(aResponse().withStatus(500)));
    }

    /** Every login update answers 409 (another Keycloak user owns the e-mail). */
    public static void loginUpdateConflicts(WireMockServer server) {
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(409)
                .withHeader("Content-Type", "application/json")
                .withBody("{\"errorMessage\":\"User exists with same email\"}")));
    }

    public static void loginUpdateFails(WireMockServer server) {
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(500)));
    }

    public static void createUserFails(WireMockServer server) {
        server.stubFor(post(urlEqualTo(USERS)).willReturn(aResponse().withStatus(500)));
    }

    public static RequestPatternBuilder userCreated() {
        return postRequestedFor(urlEqualTo(USERS));
    }

    /** A temporary password credential ({@code type=password, temporary=true}) set for {@code subject}. */
    public static RequestPatternBuilder temporaryPasswordSet(String subject) {
        return putRequestedFor(urlPathEqualTo(USERS + "/" + subject + "/reset-password"))
                .withRequestBody(matchingJsonPath("$.type", equalTo("password")))
                .withRequestBody(matchingJsonPath("$.temporary", equalTo("true")))
                .withRequestBody(matchingJsonPath("$.value", matching("[A-Za-z2-9]{16}")));
    }

    public static RequestPatternBuilder anyPasswordReset() {
        return putRequestedFor(urlPathMatching(USERS + "/[^/]+/reset-password"));
    }

    /** The value of the last temporary password sent to Keycloak for {@code subject} (read from the request journal). */
    public static String temporaryPasswordSentFor(WireMockServer server, String subject) {
        var requests = server.findAll(putRequestedFor(urlPathEqualTo(USERS + "/" + subject + "/reset-password")));
        if (requests.isEmpty()) {
            throw new AssertionError("no reset-password request for " + subject);
        }
        String body = requests.get(requests.size() - 1).getBodyAsString();
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().readTree(body).path("value").asText();
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }

    /** The login update of {@code subject} moving it to {@code email} (username = e-mail, unverified). */
    public static RequestPatternBuilder loginMoved(String subject, String email) {
        return putRequestedFor(urlPathEqualTo(USERS + "/" + subject))
                .withRequestBody(matchingJsonPath("$.username", equalTo(email)))
                .withRequestBody(matchingJsonPath("$.email", equalTo(email)))
                .withRequestBody(matchingJsonPath("$.emailVerified", equalTo("false")));
    }

    public static RequestPatternBuilder anyLoginUpdate() {
        return putRequestedFor(urlPathMatching(USERS + "/[^/]+"));
    }

    /** Any execute-actions e-mail: must never happen any more (ADR-0024). */
    public static RequestPatternBuilder anySetupEmail() {
        return putRequestedFor(urlPathMatching(USERS + "/[^/]+/execute-actions-email"));
    }

    public static RequestPatternBuilder userDeleted(String subject) {
        return deleteRequestedFor(urlPathEqualTo(USERS + "/" + subject));
    }

    public static RequestPatternBuilder anyUserDeleted() {
        return deleteRequestedFor(urlPathMatching(USERS + "/[^/]+"));
    }
}
