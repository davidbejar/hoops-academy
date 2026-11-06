package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.members.TemporaryPasswordGenerator;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.testsupport.KeycloakBrowser;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.keycloak.admin.client.CreatedResponseUtil;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.RealmResource;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.UserRepresentation;

/**
 * The realm's login hardening of ADR-0038 on a real Keycloak 26 with the academy realm, the hoops theme and the
 * password blocklist: generated temporary passwords pass the policy, a listed password is refused in any letter case
 * and with the theme's message at the first sign-in, OTP is offered to every login, forced on none and asked at every
 * sign-in once set up, and the login pages carry the realm's CSP. Run with {@code ./mvnw -pl services/core-service verify -Pkeycloak-it}.
 */
@Tag("keycloak")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
class RealmLoginHardeningKeycloakTest {

    /** On the shipped list (infra/keycloak/password-blocklist), 12 characters: only the list refuses it. */
    private static final String BLOCKED = "123qweasdzxc";

    @Inject
    IdentityProviderPort identityProvider;

    @Inject
    TemporaryPasswordGenerator generator;

    @Inject
    Keycloak serviceAccount;

    @Test
    void generatedTemporaryPasswordsPassTheWholePasswordPolicy() {
        ProvisionedIdentity login = provision("generated");

        IntStream.range(0, 25).forEach(i -> identityProvider.setTemporaryPassword(login.subject(), generator.next()));

        identityProvider.delete(login.subject());
    }

    @Test
    void aListedPasswordIsRefusedInAnyLetterCase() {
        ProvisionedIdentity login = provision("listed");

        assertThatThrownBy(() -> identityProvider.setTemporaryPassword(login.subject(), TemporaryPassword.of(BLOCKED)))
                .isInstanceOf(IdentityProviderException.class);
        assertThatThrownBy(() -> realm().users().get(login.subject()).resetPassword(permanent("123QWEasdZXC")))
                .isInstanceOfSatisfying(WebApplicationException.class, e -> {
                    assertThat(e.getResponse().getStatus()).isEqualTo(400);
                    assertThat(e.getResponse().readEntity(String.class)).contains("invalidPasswordBlacklistedMessage");
                });
        identityProvider.delete(login.subject());
    }

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "en | This password is too common and easy to guess. Choose another one.",
            "es | Esta contraseña es demasiado común y fácil de adivinar. Elige otra.",
            "id | Kata sandi ini terlalu umum dan mudah ditebak. Pilih kata sandi lain."})
    void choosingAListedPasswordAtTheFirstSignInShowsTheThemeMessage(String locale, String message) {
        // the login's own locale (set when core creates it) wins over ui_locales once Keycloak knows the user
        ProvisionedIdentity login = provision("first-" + locale, AppLocale.fromCode(locale));
        TemporaryPassword temporary = generator.next();
        identityProvider.setTemporaryPassword(login.subject(), temporary);
        String email = realm().users().get(login.subject()).toRepresentation().getEmail();

        KeycloakBrowser browser = new KeycloakBrowser().open(locale)
                .submit("kc-form-login", Map.of("username", email, "password", temporary.reveal()))
                .submit("kc-passwd-update-form", Map.of("password-new", BLOCKED, "password-confirm", BLOCKED));

        assertThat(browser.signedIn()).isFalse();
        assertThat(browser.page()).contains(message).contains("kc-passwd-update-form");
        identityProvider.delete(login.subject());
    }

    @Test
    void otpIsOfferedButNotForcedAndOnceSetUpItIsAskedAtEverySignIn() throws GeneralSecurityException {
        String password = "Own-" + UUID.randomUUID();
        String subject = createUser("otp", password);
        String email = email(subject);

        KeycloakBrowser browser = new KeycloakBrowser().open("en")
                .submit("kc-form-login", Map.of("username", email, "password", password));
        assertThat(browser.signedIn()).as("no OTP step, no forced set-up").isTrue();

        // the person sets it up (account console: "Set up authenticator application" = this application action)
        browser.open("en", Map.of("kc_action", "CONFIGURE_TOTP"));
        assertThat(browser.page()).contains("kc-totp-settings-form").contains("kc-totp-secret-qr-code");
        String secret = browser.input("totpSecret");
        long step = browser.serverEpochSecond() / 30;
        browser.submit("kc-totp-settings-form", Map.of("totpSecret", secret, "totp", totp(secret, step),
                "userLabel", "test app"));
        assertThat(browser.signedIn()).as("set-up accepted").isTrue();

        KeycloakBrowser next = new KeycloakBrowser().open("en")
                .submit("kc-form-login", Map.of("username", email, "password", password));
        assertThat(next.signedIn()).as("password alone").isFalse();
        assertThat(next.page()).contains("kc-otp-login-form");
        // the next time step: a code is used once only (otpPolicyCodeReusable false), the look-ahead window takes it
        next.submit("kc-otp-login-form", Map.of("otp", totp(secret, step + 1)));
        assertThat(next.signedIn()).as("password + code").isTrue();
        identityProvider.delete(subject);
    }

    @Test
    void theLoginPageCarriesTheRealmsSecurityHeaders() {
        KeycloakBrowser browser = new KeycloakBrowser().open("en");

        assertThat(browser.response().headers().firstValue("Content-Security-Policy")).hasValueSatisfying(csp ->
                assertThat(csp).startsWith("default-src 'self'; script-src 'self' 'unsafe-inline';")
                        .contains("frame-ancestors 'self'; form-action 'self' http://localhost:5173;")
                        .contains("object-src 'none';"));
        assertThat(browser.response().headers().firstValue("X-Frame-Options")).hasValue("SAMEORIGIN");
        assertThat(browser.response().headers().firstValue("Referrer-Policy")).hasValue("no-referrer");
    }

    private ProvisionedIdentity provision(String prefix) {
        return provision(prefix, AppLocale.EN);
    }

    private ProvisionedIdentity provision(String prefix, AppLocale locale) {
        return identityProvider.provision(new NewIdentity(prefix + "-" + UUID.randomUUID() + "@example.com",
                "Hard", "Ening", locale));
    }

    private String createUser(String prefix, String password) {
        String email = prefix + "-" + UUID.randomUUID() + "@example.com";
        UserRepresentation user = new UserRepresentation();
        user.setUsername(email);
        user.setEmail(email);
        user.setFirstName("Otp");
        user.setLastName("Tester");
        user.setEnabled(true);
        user.setEmailVerified(true);
        user.setCredentials(List.of(permanent(password)));
        try (Response created = realm().users().create(user)) {
            return CreatedResponseUtil.getCreatedId(created);
        }
    }

    private String email(String subject) {
        return realm().users().get(subject).toRepresentation().getEmail();
    }

    private RealmResource realm() {
        return serviceAccount.realm("academy");
    }

    private static CredentialRepresentation permanent(String value) {
        CredentialRepresentation credential = new CredentialRepresentation();
        credential.setType(CredentialRepresentation.PASSWORD);
        credential.setTemporary(false);
        credential.setValue(value);
        return credential;
    }

    /** RFC 6238 with HMAC-SHA1 over the secret's UTF-8 bytes, as Keycloak's TimeBasedOTP computes it. */
    private static String totp(String secret, long step) throws GeneralSecurityException {
        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA1"));
        byte[] hash = mac.doFinal(ByteBuffer.allocate(Long.BYTES).putLong(step).array());
        int offset = hash[hash.length - 1] & 0x0f;
        int binary = ((hash[offset] & 0x7f) << 24) | ((hash[offset + 1] & 0xff) << 16)
                | ((hash[offset + 2] & 0xff) << 8) | (hash[offset + 3] & 0xff);
        return String.format("%06d", binary % 1_000_000);
    }
}
