package com.hoopsacademy.core.testsupport;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.ConfigProvider;

/**
 * A browser without JavaScript on the realm's login pages (client {@code web}, authorization code + PKCE, theme
 * {@code hoops}) of {@link KeycloakContainerResource}: keeps the cookies by hand (Keycloak marks them Secure, even on
 * http), follows Keycloak's redirects between its own pages and submits forms by id. One instance is one sign-in.
 */
public final class KeycloakBrowser {

    /** Registered on client {@code web}; Keycloak redirects here with the code, which is never fetched. */
    public static final String REDIRECT = "http://localhost:8080/";

    private final HttpClient http = HttpClient.newHttpClient(); // does not follow redirects
    private final Map<String, String> cookies = new LinkedHashMap<>();
    private HttpResponse<String> current;

    /** Opens the login page in {@code locale} ({@code ui_locales}). */
    public KeycloakBrowser open(String locale) {
        return open(locale, Map.of());
    }

    /**
     * Opens the authorization endpoint with extra parameters, e.g. {@code kc_action=CONFIGURE_TOTP} (what the account
     * console's "set up authenticator application" does); with this browser's session no login form is shown.
     */
    public KeycloakBrowser open(String locale, Map<String, String> extra) {
        String verifier = UUID.randomUUID() + "-" + UUID.randomUUID();
        String challenge;
        try {
            challenge = Base64.getUrlEncoder().withoutPadding().encodeToString(
                    MessageDigest.getInstance("SHA-256").digest(verifier.getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
        String realm = ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class)
                .replace("/protocol/openid-connect/token", "");
        Map<String, String> query = new LinkedHashMap<>(Map.of("client_id", "web", "redirect_uri", REDIRECT,
                "response_type", "code", "scope", "openid", "code_challenge", challenge,
                "code_challenge_method", "S256", "ui_locales", locale));
        query.putAll(extra);
        return get(URI.create(realm + "/protocol/openid-connect/auth?" + form(query)));
    }

    /** Fills and submits the form with this id; follows redirects among Keycloak's pages. */
    public KeycloakBrowser submit(String formId, Map<String, String> fields) {
        Matcher action = Pattern.compile("<form[^>]*id=\"" + formId + "\"[^>]*action=\"([^\"]+)\"").matcher(page());
        if (!action.find()) {
            action = Pattern.compile("<form[^>]*action=\"([^\"]+)\"[^>]*id=\"" + formId + "\"").matcher(page());
            if (!action.find()) {
                throw new AssertionError("no form " + formId + " in " + page());
            }
        }
        URI target = current.uri().resolve(action.group(1).replace("&amp;", "&"));
        return follow(send(HttpRequest.newBuilder(target)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form(fields)))));
    }

    /** The value of the input {@code name} on the current page (e.g. a hidden field). */
    public String input(String name) {
        Matcher input = Pattern.compile("<input[^>]*name=\"" + name + "\"[^>]*value=\"([^\"]*)\"").matcher(page());
        if (!input.find()) {
            input = Pattern.compile("<input[^>]*value=\"([^\"]*)\"[^>]*name=\"" + name + "\"").matcher(page());
            if (!input.find()) {
                throw new AssertionError("no input " + name + " in " + page());
            }
        }
        return input.group(1);
    }

    /**
     * Keycloak's clock as of the last answer (its {@code Date} header, which the Podman VM's clock sets), else this
     * JVM's (Keycloak's pages send no {@code Date}; the commit hook keeps the VM clock in sync).
     */
    public long serverEpochSecond() {
        return current.headers().firstValue("Date")
                .map(date -> ZonedDateTime.parse(date, DateTimeFormatter.RFC_1123_DATE_TIME).toEpochSecond())
                .orElseGet(() -> System.currentTimeMillis() / 1000);
    }

    /** The page shown now (empty for a redirect out of Keycloak). */
    public String page() {
        return current.body() == null ? "" : current.body();
    }

    public HttpResponse<String> response() {
        return current;
    }

    /** True when Keycloak sent the browser back to the app with an authorization code. */
    public boolean signedIn() {
        String location = current.headers().firstValue("Location").orElse("");
        return current.statusCode() == 302 && location.startsWith(REDIRECT) && location.contains("code=");
    }

    private KeycloakBrowser get(URI uri) {
        return follow(send(HttpRequest.newBuilder(uri).GET()));
    }

    private KeycloakBrowser follow(HttpResponse<String> response) {
        current = response;
        for (int hops = 0; hops < 5 && current.statusCode() == 302; hops++) {
            String location = current.headers().firstValue("Location").orElse("");
            if (location.startsWith(REDIRECT)) {
                break;
            }
            current = send(HttpRequest.newBuilder(current.uri().resolve(location)).GET());
        }
        return this;
    }

    private HttpResponse<String> send(HttpRequest.Builder request) {
        if (!cookies.isEmpty()) {
            request.header("Cookie", cookies.entrySet().stream().map(e -> e.getKey() + "=" + e.getValue())
                    .collect(Collectors.joining("; ")));
        }
        try {
            HttpResponse<String> response = http.send(request.build(),
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            for (String cookie : response.headers().allValues("Set-Cookie")) {
                String pair = cookie.split(";", 2)[0];
                int eq = pair.indexOf('=');
                if (eq > 0) {
                    cookies.put(pair.substring(0, eq).trim(), pair.substring(eq + 1).trim());
                }
            }
            return response;
        } catch (IOException e) {
            throw new IllegalStateException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    private static String form(Map<String, String> fields) {
        return fields.entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
    }
}
