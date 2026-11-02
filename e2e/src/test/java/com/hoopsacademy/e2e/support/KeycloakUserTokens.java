package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.net.URLDecoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Browser-less OIDC authorization-code + PKCE login for the public client {@code web} (direct grants are disabled):
 * GET the auth endpoint (cookie jar), parse the {@code kc-form-login} action, POST the credentials, read the code from
 * the 302 {@code Location}, exchange it with the verifier. Port of {@code apps/web/tool/keycloak_login_check.sh}.
 * Also service tokens (client credentials) for the {@code /internal} checks.
 */
public final class KeycloakUserTokens {
    private static final Pattern FORM_ACTION = Pattern.compile("id=\"kc-form-login\"[^>]*action=\"([^\"]*)\"", Pattern.DOTALL);
    private static final Pattern FORM_ACTION_REV = Pattern.compile("action=\"([^\"]*)\"[^>]*id=\"kc-form-login\"", Pattern.DOTALL);
    private static final Pattern UPDATE_PASSWORD_FORM =
            Pattern.compile("id=\"kc-passwd-update-form\"[^>]*action=\"([^\"]*)\"", Pattern.DOTALL);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final String issuer = E2eEnv.baseUrl() + "/auth/realms/academy";
    /** Must match a redirect URI registered on client `web` (`<public url>/*`: :8080 on compose, :8090 on kind). */
    private final String redirect = envOr("E2E_REDIRECT_URI", E2eEnv.baseUrl() + "/redirect.html");

    private static String envOr(String name, String fallback) {
        String v = System.getenv(name);
        return v == null || v.isBlank() ? fallback : v;
    }

    private static String b64url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** @return the access token of {@code username}. */
    public String login(String username, String password) {
        return login(username, password, null);
    }

    /**
     * First sign-in with a temporary password (ADR-0024): Keycloak must answer the credentials with its "update
     * password" page (required action UPDATE_PASSWORD, form {@code kc-passwd-update-form}) instead of a code; the new
     * password is submitted there, as a person would in the browser, and the code exchanged as usual.
     *
     * @return the access token of {@code username}, now signed in with {@code newPassword}
     */
    public String firstLogin(String username, String temporaryPassword, String newPassword) {
        return login(username, temporaryPassword, newPassword);
    }

    private String login(String username, String password, String newPassword) {
        byte[] v = new byte[48];
        RANDOM.nextBytes(v);
        String verifier = b64url(v);
        String challenge;
        try {
            challenge = b64url(MessageDigest.getInstance("SHA-256").digest(verifier.getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
        String state = Long.toHexString(RANDOM.nextLong());
        HttpClient http = Http.client(null);
        Map<String, String> jar = new LinkedHashMap<>(); // JDK CookieManager drops `Secure` cookies on http://, which Keycloak sets

        Map<String, String> q = new LinkedHashMap<>();
        q.put("client_id", "web");
        q.put("response_type", "code");
        q.put("redirect_uri", redirect);
        q.put("scope", "openid profile email");
        q.put("state", state);
        q.put("code_challenge", challenge);
        q.put("code_challenge_method", "S256");
        HttpResponse<String> page = Http.send(http, HttpRequest.newBuilder(
                URI.create(issuer + "/protocol/openid-connect/auth?" + Http.form(q))).GET().build());
        remember(jar, page);
        if (page.statusCode() != 200) {
            throw new IllegalStateException("login page -> " + page.statusCode() + " (redirect URI registered on client web?)");
        }
        String action = formAction(page.body());

        HttpResponse<String> submit = Http.send(http, HttpRequest.newBuilder(URI.create(action))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .header("Cookie", cookieHeader(jar))
                .POST(HttpRequest.BodyPublishers.ofString(Http.form(Map.of("username", username, "password", password)))).build());
        remember(jar, submit);
        if (newPassword != null) {
            submit = updatePassword(http, jar, username, submit, newPassword);
        }
        String location = submit.headers().firstValue("Location").orElse("");
        if (submit.statusCode() != 302 || !location.startsWith(redirect)) {
            Matcher err = Pattern.compile("kc-feedback-text\">([^<]*)<|id=\"kc-error-message\">\\s*<p[^>]*>([^<]*)<", Pattern.DOTALL)
                    .matcher(submit.body() == null ? "" : submit.body());
            String why = err.find() ? (err.group(1) != null ? err.group(1) : err.group(2)) : "no message in page";
            throw new IllegalStateException("login of " + username + " did not redirect with a code (status "
                    + submit.statusCode() + ", keycloak says: " + why.strip() + "): wrong password, required action or disabled user");
        }
        Map<String, String> params = queryOf(location);
        if (!state.equals(params.get("state")) || params.get("code") == null) {
            throw new IllegalStateException("state mismatch or missing code for " + username);
        }
        JsonNode tokens = Http.json(Http.postForm(http, issuer + "/protocol/openid-connect/token", Map.of(
                "grant_type", "authorization_code", "client_id", "web", "code", params.get("code"),
                "redirect_uri", redirect, "code_verifier", verifier)), 200);
        return tokens.get("access_token").asText();
    }

    private HttpResponse<String> updatePassword(HttpClient http, Map<String, String> jar, String username,
            HttpResponse<String> answer, String newPassword) {
        // Keycloak redirects to its required-action page (login-actions/required-action?execution=UPDATE_PASSWORD)
        HttpResponse<String> credentialsAnswer = answer;
        for (int hops = 0; hops < 5 && credentialsAnswer.statusCode() == 302; hops++) {
            String next = credentialsAnswer.headers().firstValue("Location").orElse("");
            if (next.startsWith(redirect)) {
                throw new IllegalStateException("the temporary password of " + username + " signed in without asking "
                        + "for a new password");
            }
            credentialsAnswer = Http.send(http, HttpRequest.newBuilder(credentialsAnswer.uri().resolve(next))
                    .header("Cookie", cookieHeader(jar)).GET().build());
            remember(jar, credentialsAnswer);
        }
        String page = credentialsAnswer.body() == null ? "" : credentialsAnswer.body();
        Matcher form = UPDATE_PASSWORD_FORM.matcher(page);
        if (credentialsAnswer.statusCode() != 200 || !form.find()) {
            throw new IllegalStateException("the temporary password of " + username + " did not lead to Keycloak's "
                    + "update-password page (status " + credentialsAnswer.statusCode() + ")");
        }
        HttpResponse<String> updated = Http.send(http, HttpRequest.newBuilder(URI.create(form.group(1).replace("&amp;", "&")))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .header("Cookie", cookieHeader(jar))
                .POST(HttpRequest.BodyPublishers.ofString(Http.form(Map.of(
                        "password-new", newPassword, "password-confirm", newPassword)))).build());
        remember(jar, updated);
        return updated;
    }

    /** True when the JWT payload has a {@code sub} claim (the realm defect of WP18 bug 1 removes it). */
    public static boolean hasSub(String jwt) {
        String payload = new String(Base64.getUrlDecoder().decode(jwt.split("\\.")[1]), StandardCharsets.UTF_8);
        return payload.contains("\"sub\":");
    }

    /** Client-credentials token of a service client, e.g. {@code core-service} with CORE_SERVICE_CLIENT_SECRET. */
    public String serviceToken(String clientId, String secretEnvVar) {
        HttpClient http = Http.client(null);
        return Http.json(Http.postForm(http, issuer + "/protocol/openid-connect/token", Map.of(
                "grant_type", "client_credentials", "client_id", clientId, "client_secret", E2eEnv.required(secretEnvVar))), 200)
                .get("access_token").asText();
    }

    private static void remember(Map<String, String> jar, HttpResponse<?> r) {
        for (String sc : r.headers().allValues("Set-Cookie")) {
            String pair = sc.split(";", 2)[0];
            int i = pair.indexOf('=');
            if (i > 0) {
                jar.put(pair.substring(0, i).trim(), pair.substring(i + 1).trim());
            }
        }
    }

    private static String cookieHeader(Map<String, String> jar) {
        return jar.entrySet().stream().map(e -> e.getKey() + "=" + e.getValue()).collect(java.util.stream.Collectors.joining("; "));
    }

    static String formAction(String html) {
        Matcher m = FORM_ACTION.matcher(html);
        if (!m.find()) {
            m = FORM_ACTION_REV.matcher(html);
            if (!m.find()) {
                throw new IllegalStateException("kc-form-login not found on the Keycloak login page");
            }
        }
        return m.group(1).replace("&amp;", "&");
    }

    private static Map<String, String> queryOf(String url) {
        Map<String, String> out = new LinkedHashMap<>();
        String raw = URI.create(url).getRawQuery();
        if (raw == null) {
            return out;
        }
        for (String kv : raw.split("&")) {
            int i = kv.indexOf('=');
            if (i > 0) {
                out.put(kv.substring(0, i), URLDecoder.decode(kv.substring(i + 1), StandardCharsets.UTF_8));
            }
        }
        return out;
    }
}
