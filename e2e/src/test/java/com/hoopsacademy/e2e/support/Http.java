package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import java.util.stream.Collectors;

/** Tiny JDK HttpClient helpers for the identity-provider and mail plumbing (the API under test uses REST Assured). */
final class Http {
    static final ObjectMapper JSON = new ObjectMapper();

    private Http() {}

    static HttpClient client(java.net.CookieHandler cookies) {
        HttpClient.Builder b = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NEVER)
                .connectTimeout(Duration.ofSeconds(10));
        if (cookies != null) {
            b.cookieHandler(cookies);
        }
        return b.build();
    }

    static String form(Map<String, String> fields) {
        return fields.entrySet().stream()
                .map(e -> URLEncoder.encode(e.getKey(), StandardCharsets.UTF_8) + "="
                        + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
    }

    static HttpResponse<String> send(HttpClient c, HttpRequest r) {
        try {
            return c.send(r, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new IllegalStateException(r.method() + " " + r.uri().getPath() + " failed: " + e.getMessage(), e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    static HttpResponse<String> postForm(HttpClient c, String url, Map<String, String> fields) {
        return send(c, HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form(fields))).build());
    }

    static JsonNode json(HttpResponse<String> r, int expectedStatus) {
        if (r.statusCode() != expectedStatus) {
            throw new IllegalStateException(r.request().method() + " " + r.request().uri().getPath() + " -> "
                    + r.statusCode() + " (expected " + expectedStatus + ")");
        }
        try {
            return r.body() == null || r.body().isBlank() ? JSON.createObjectNode() : JSON.readTree(r.body());
        } catch (IOException e) {
            throw new IllegalStateException("not JSON: " + r.request().uri().getPath(), e);
        }
    }
}
