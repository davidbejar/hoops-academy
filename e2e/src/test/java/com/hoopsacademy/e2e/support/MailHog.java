package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Optional;

/** Reads the MailHog HTTP API v2 ({@code /api/v2/messages}). */
public final class MailHog {
    private final String base = E2eEnv.mailhogUrl();
    private final HttpClient http = Http.client(null);

    public boolean reachable() {
        try {
            return http.send(HttpRequest.newBuilder(URI.create(base + "/api/v2/messages?limit=1")).GET().build(),
                    HttpResponse.BodyHandlers.discarding()).statusCode() == 200;
        } catch (java.io.IOException e) {
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    /** The newest message addressed to {@code recipient}, if any. */
    public Optional<JsonNode> latestTo(String recipient) {
        JsonNode all = Http.json(Http.send(http, HttpRequest.newBuilder(URI.create(base + "/api/v2/messages?limit=250")).GET().build()), 200);
        for (JsonNode m : all.get("items")) {
            for (JsonNode to : m.get("To")) {
                if (recipient.equalsIgnoreCase(to.get("Mailbox").asText() + "@" + to.get("Domain").asText())) {
                    return Optional.of(m);
                }
            }
        }
        return Optional.empty();
    }
}
