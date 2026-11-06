package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

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

    private static boolean anyTo(JsonNode messages, String recipient, boolean mailhogShape) {
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
