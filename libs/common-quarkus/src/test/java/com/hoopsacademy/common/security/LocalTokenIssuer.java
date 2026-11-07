package com.hoopsacademy.common.security;

import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import io.smallrye.jwt.build.Jwt;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;

/**
 * Real bearer-token validation without Keycloak: a key pair made per test run, its public key configured as
 * {@code quarkus.oidc.public-key}, tokens signed in the test (no key in git). Inject {@link Tokens} into the test.
 */
public class LocalTokenIssuer implements QuarkusTestResourceLifecycleManager {

    static final String AUDIENCE = "probe-service";
    static final String ISSUER = "https://issuer.test/realms/academy";

    private KeyPair keys;

    @Override
    public Map<String, String> start() {
        keys = rsa();
        return Map.of(
                "quarkus.oidc.tenant-enabled", "true",
                "quarkus.oidc.public-key", Base64.getEncoder().encodeToString(keys.getPublic().getEncoded()),
                "quarkus.oidc.token.audience", AUDIENCE,
                "quarkus.oidc.token.issuer", ISSUER);
    }

    @Override
    public void inject(TestInjector injector) {
        injector.injectIntoFields(new Tokens(keys.getPrivate()),
                new TestInjector.MatchesType(Tokens.class));
    }

    @Override
    public void stop() {
        keys = null;
    }

    static KeyPair rsa() {
        try {
            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            return generator.generateKeyPair();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Signs test tokens with the configured key (or another one). */
    public record Tokens(PrivateKey key) {

        String valid(String subject) {
            return sign(subject, AUDIENCE, Instant.now().plusSeconds(300), key);
        }

        String expired(String subject) {
            return sign(subject, AUDIENCE, Instant.now().minusSeconds(600), key);
        }

        String forAudience(String subject, String audience) {
            return sign(subject, audience, Instant.now().plusSeconds(300), key);
        }

        String signedByAnotherKey(String subject) {
            return sign(subject, AUDIENCE, Instant.now().plusSeconds(300), rsa().getPrivate());
        }

        private static String sign(String subject, String audience, Instant expiresAt, PrivateKey signer) {
            return Jwt.issuer(ISSUER).subject(subject).audience(audience)
                    .issuedAt(expiresAt.minusSeconds(900)).expiresAt(expiresAt)
                    .sign(signer);
        }
    }
}
