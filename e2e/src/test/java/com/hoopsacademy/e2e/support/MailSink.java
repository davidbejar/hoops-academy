package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;

/**
 * Reads the SMTP sink behind {@code E2E_MAILHOG_URL}: MailHog (compose, {@code /api/v2/messages}) or Mailpit (kind,
 * {@code /api/v1/messages}). The API is detected on first use: MailHog's v2 endpoint first (Mailpit answers 404), then
 * Mailpit's v1 endpoint, recognised by the {@code messages} array (MailHog's own v1 returns a bare array).
 */
public final class MailSink {
    private enum Api { MAILHOG_V2, MAILPIT_V1, NONE }

    private final String base;
    private final HttpClient http = Http.client(null);
    private Api api;

    public MailSink() {
        this(E2eEnv.mailUrl());
    }

    MailSink(String base) {
        this.base = base;
    }

    public boolean reachable() {
        return api() != Api.NONE;
    }

    /** True when the sink holds a message addressed to {@code recipient} (case-insensitive). */
    public boolean hasMessageTo(String recipient) {
        return switch (api()) {
            case MAILHOG_V2 -> anyTo(list("/api/v2/messages?limit=250").get("items"), recipient, true);
            case MAILPIT_V1 -> anyTo(list("/api/v1/messages?limit=250").get("messages"), recipient, false);
            case NONE -> throw new IllegalStateException("no MailHog/Mailpit API answers at " + base);
        };
    }

    /**
     * The plain-text body of the newest message to {@code recipient} (case-insensitive), or null. MailHog keeps the raw
     * body (quoted-printable soft line breaks and {@code =XX} escapes are decoded here); Mailpit serves the decoded text
     * per message.
     */
    public String textTo(String recipient) {
        return switch (api()) {
            case MAILHOG_V2 -> {
                JsonNode message = newestTo(list("/api/v2/messages?limit=250").get("items"), recipient, true);
                yield message == null ? null : decodeQuotedPrintable(message.path("Content").path("Body").asText());
            }
            case MAILPIT_V1 -> {
                JsonNode message = newestTo(list("/api/v1/messages?limit=250").get("messages"), recipient, false);
                yield message == null ? null : list("/api/v1/message/" + message.get("ID").asText()).path("Text").asText();
            }
            case NONE -> throw new IllegalStateException("no MailHog/Mailpit API answers at " + base);
        };
    }

    /** Both APIs list the newest message first. */
    private static JsonNode newestTo(JsonNode messages, String recipient, boolean mailhogShape) {
        for (JsonNode m : messages) {
            if (anyTo(List.of(m), recipient, mailhogShape)) {
                return m;
            }
        }
        return null;
    }

    static String decodeQuotedPrintable(String body) {
        String joined = body.replace("=\r\n", "").replace("=\n", "");
        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
        for (int i = 0; i < joined.length(); i++) {
            char c = joined.charAt(i);
            if (c == '=' && i + 2 < joined.length() && isHex(joined.charAt(i + 1)) && isHex(joined.charAt(i + 2))) {
                out.write(Integer.parseInt(joined.substring(i + 1, i + 3), 16));
                i += 2;
            } else {
                byte[] bytes = String.valueOf(c).getBytes(java.nio.charset.StandardCharsets.UTF_8);
                out.write(bytes, 0, bytes.length);
            }
        }
        return out.toString(java.nio.charset.StandardCharsets.UTF_8);
    }

    private static boolean isHex(char c) {
        return Character.digit(c, 16) >= 0;
    }

    private static boolean anyTo(Iterable<JsonNode> messages, String recipient, boolean mailhogShape) {
        for (JsonNode m : messages) {
            for (JsonNode to : m.get("To")) {
                String address = mailhogShape
                        ? to.get("Mailbox").asText() + "@" + to.get("Domain").asText()
                        : to.get("Address").asText();
                if (recipient.equalsIgnoreCase(address)) {
                    return true;
                }
            }
        }
        return false;
    }

    private JsonNode list(String path) {
        return Http.json(Http.send(http, get(path)), 200);
    }

    private HttpRequest get(String path) {
        return HttpRequest.newBuilder(URI.create(base + path)).GET().build();
    }

    private Api api() {
        if (api == null) {
            api = detect();
        }
        return api;
    }

    private Api detect() {
        try {
            if (http.send(get("/api/v2/messages?limit=1"), HttpResponse.BodyHandlers.discarding()).statusCode() == 200) {
                return Api.MAILHOG_V2;
            }
            HttpResponse<String> v1 = http.send(get("/api/v1/messages?limit=1"), HttpResponse.BodyHandlers.ofString());
            if (v1.statusCode() == 200 && Http.JSON.readTree(v1.body()).has("messages")) {
                return Api.MAILPIT_V1;
            }
        } catch (java.io.IOException e) {
            return Api.NONE;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return Api.NONE;
    }
}
