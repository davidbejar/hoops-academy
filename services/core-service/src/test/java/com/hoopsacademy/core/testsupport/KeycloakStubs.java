package com.hoopsacademy.core.testsupport;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.delete;
import static com.github.tomakehurst.wiremock.client.WireMock.deleteRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.matching;
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

    /** Token endpoint, "no user with that e-mail", create → 201 with a fresh id, actions e-mail and delete → 204. */
    public static void installDefaults(WireMockServer server) {
        server.resetAll();
        server.stubFor(post(urlEqualTo(TOKEN)).willReturn(okJson(TOKEN_BODY)));
        server.stubFor(get(urlPathEqualTo(USERS)).willReturn(okJson("[]")));
        server.stubFor(post(urlEqualTo(USERS)).willReturn(aResponse().withStatus(201)
                .withHeader("Location", server.baseUrl() + USERS + "/{{randomValue type='UUID'}}")));
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+/execute-actions-email"))
                .willReturn(aResponse().withStatus(204)));
        server.stubFor(delete(urlPathMatching(USERS + "/[^/]+")).willReturn(aResponse().withStatus(204)));
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

    public static void createUserFails(WireMockServer server) {
        server.stubFor(post(urlEqualTo(USERS)).willReturn(aResponse().withStatus(500)));
    }

    public static void setupEmailFails(WireMockServer server) {
        server.stubFor(put(urlPathMatching(USERS + "/[^/]+/execute-actions-email"))
                .willReturn(aResponse().withStatus(500)));
    }

    public static RequestPatternBuilder userCreated() {
        return postRequestedFor(urlEqualTo(USERS));
    }

    public static RequestPatternBuilder setupEmailSent(String subject) {
        return putRequestedFor(urlPathEqualTo(USERS + "/" + subject + "/execute-actions-email"))
                .withRequestBody(matching(".*UPDATE_PASSWORD.*"))
                .withRequestBody(matching(".*VERIFY_EMAIL.*"));
    }

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
