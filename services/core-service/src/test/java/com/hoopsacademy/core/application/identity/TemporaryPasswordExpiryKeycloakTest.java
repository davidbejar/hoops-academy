package com.hoopsacademy.core.application.identity;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.members.IssueTemporaryPassword;
import com.hoopsacademy.core.application.members.LoginEmailSync.SharedLogin;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import com.hoopsacademy.core.testsupport.Members;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.net.CookieManager;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.UserResource;
import org.keycloak.representations.idm.CredentialRepresentation;

/**
 * Temporary password expiry end to end against a real Keycloak 26 (ADR-0028): the sweep disables a login whose
 * temporary password was issued more than three days ago, a re-issue enables it again with a new temporary password
 * (Keycloak asks for a new password), and the branded login page tells a disabled person what happened. Run with
 * {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
 */
@Tag("keycloak")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
class TemporaryPasswordExpiryKeycloakTest {

    private static final String NOT_SET_UP = "Account is not fully set up";
    private static final String DISABLED = "Account disabled";
    private static final String INVALID = "Invalid user credentials";

    @Inject
    IdentityProviderPort identityProvider;

    @Inject
    Keycloak serviceAccount;

    @Inject
    ExpireTemporaryPasswords sweep;

    @Inject
    IssueTemporaryPassword issueTemporaryPassword;

    @Inject
    TenantScope tenantScope;

    @Test
    void anUnusedTemporaryPasswordIssuedFourDaysAgoStopsSigningInUntilANewOneIsIssued() throws Exception {
        Pending pending = pendingPerson("late");
        String first = issue(pending);
        assertThat(directGrant(pending.email(), first)).as("valid, update pending").contains(NOT_SET_UP);
        CoreDb.temporaryPasswordIssued(pending.login().subject(), "4 days");

        sweep.run();

        assertThat(user(pending).toRepresentation().isEnabled()).isFalse();
        assertThat(directGrant(pending.email(), first)).contains(DISABLED);
        assertThat(CoreDb.auditRow(pending.tenant(), "member.temporary_password_expired"))
                .containsEntry("targetId", pending.person().value().toString());

        String renewed = issue(pending);

        assertThat(user(pending).toRepresentation().isEnabled()).isTrue();
        assertThat(directGrant(pending.email(), renewed)).as("Keycloak asks for a new password").contains(NOT_SET_UP);
        assertThat(directGrant(pending.email(), first)).as("the old one is gone").contains(INVALID);
        String chosen = "Chosen-" + UUID.randomUUID();
        user(pending).resetPassword(permanent(chosen)); // what the update-password page does at the first sign-in
        assertThat(directGrant(pending.email(), chosen)).contains("access_token");
        identityProvider.delete(pending.login().subject());
    }

    @Test
    void aLoginWhoseOwnerChoseAPasswordStaysEnabled() throws Exception {
        Pending pending = pendingPerson("chosen");
        issue(pending);
        String chosen = "Chosen-" + UUID.randomUUID();
        user(pending).resetPassword(permanent(chosen));
        CoreDb.temporaryPasswordIssued(pending.login().subject(), "4 days");

        sweep.run();

        assertThat(user(pending).toRepresentation().isEnabled()).isTrue();
        assertThat(directGrant(pending.email(), chosen)).contains("access_token");
        assertThat(CoreDb.temporaryPassword(pending.login().subject())).containsEntry("issuedAt", null);
        identityProvider.delete(pending.login().subject());
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "en | Your temporary password has expired. Ask your academy administrator for a new one.",
            "es | Tu contraseña temporal ha caducado. Pide una nueva al administrador de tu academia.",
            "id | Kata sandi sementara Anda sudah kedaluwarsa. Mintalah yang baru kepada administrator akademi Anda."})
    void theLoginPageTellsADisabledPersonThatTheTemporaryPasswordExpired(String locale, String message)
            throws Exception {
        Pending pending = pendingPerson("page-" + locale);
        String password = issue(pending);
        CoreDb.temporaryPasswordIssued(pending.login().subject(), "4 days");
        sweep.run();

        String page = browserSignIn(pending.email(), password, locale);

        assertThat(page).contains(message);
        identityProvider.delete(pending.login().subject());
    }

    private record Pending(String tenant, String email, ProvisionedIdentity login, PersonId person) {}

    private Pending pendingPerson(String prefix) {
        String email = prefix + "-" + UUID.randomUUID() + "@example.com";
        ProvisionedIdentity login = identityProvider.provision(new NewIdentity(email, "Ex", "Piry", AppLocale.EN));
        String tenant = Members.newTenant();
        UUID person = CoreDb.person(tenant, CoreDb.appUser(login.subject(), email), "Ex", "Piry", email, null, null,
                TenantRole.COACH);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.person set invitation_status = 'PENDING' where id = ?", person));
        return new Pending(tenant, email, login, new PersonId(person));
    }

    /** What the console's re-issue does (super admin path), returning the shown-once value. */
    private String issue(Pending pending) {
        return tenantScope.runAs(TenantId.parse(pending.tenant()),
                () -> issueTemporaryPassword.handle(pending.person(), SharedLogin.SYNC))
                .temporaryPassword().orElseThrow().reveal();
    }

    private UserResource user(Pending pending) {
        return serviceAccount.realm("academy").users().get(pending.login().subject());
    }

    private static CredentialRepresentation permanent(String value) {
        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setTemporary(false);
        credential.setValue(value);
        return credential;
    }

    /** The token endpoint's raw answer to a password grant (an error description or the tokens). */
    private static String directGrant(String username, String password) throws Exception {
        String url = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class);
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form(Map.of("grant_type", "password",
                        "client_id", KeycloakContainerResource.DIRECT_GRANT_CLIENT, "username", username,
                        "password", password, "scope", "openid"))))
                .build();
        return HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

    /**
     * The page the browser shows after submitting e-mail and password on the realm's login page (client {@code web},
     * authorization code + PKCE, theme {@code hoops}) in {@code locale}.
     */
    private static String browserSignIn(String username, String password, String locale) throws Exception {
        HttpClient browser = HttpClient.newBuilder().cookieHandler(new CookieManager())
                .followRedirects(HttpClient.Redirect.NORMAL).build();
        String verifier = UUID.randomUUID() + "-" + UUID.randomUUID();
        String challenge = Base64.getUrlEncoder().withoutPadding().encodeToString(
                MessageDigest.getInstance("SHA-256").digest(verifier.getBytes(StandardCharsets.US_ASCII)));
        String realm = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class)
                .replace("/protocol/openid-connect/token", "");
        URI authorize = URI.create(realm + "/protocol/openid-connect/auth?" + form(Map.of("client_id", "web",
                "redirect_uri", "http://localhost:8080/", "response_type", "code", "scope", "openid",
                "code_challenge", challenge, "code_challenge_method", "S256", "ui_locales", locale)));
        String loginPage = browser.send(HttpRequest.newBuilder(authorize).GET().build(),
                HttpResponse.BodyHandlers.ofString()).body();
        Matcher action = Pattern.compile("<form[^>]*id=\"kc-form-login\"[^>]*action=\"([^\"]+)\"").matcher(loginPage);
        if (!action.find()) {
            action = Pattern.compile("action=\"([^\"]+login-actions/authenticate[^\"]*)\"").matcher(loginPage);
            assertThat(action.find()).as("login form in " + loginPage).isTrue();
        }
        URI submit = URI.create(action.group(1).replace("&amp;", "&"));
        HttpRequest post = HttpRequest.newBuilder(submit)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form(Map.of("username", username, "password", password,
                        "credentialId", ""))))
                .build();
        return browser.send(post, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)).body();
    }

    private static String form(Map<String, String> fields) {
        return fields.entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
    }
}
