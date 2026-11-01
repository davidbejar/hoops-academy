package com.hoopsacademy.e2e.support;

import static org.junit.jupiter.api.Assertions.fail;

import io.restassured.response.Response;
import java.util.UUID;

/** Assertions that print the Problem body (never a token) when a status differs. */
public final class Check {
    private Check() {}

    public static Response status(Response r, int expected) {
        if (r.statusCode() != expected) {
            String body = r.asString();
            fail(r.getStatusLine() + " (expected " + expected + ") for the last call; body: "
                    + (body.length() > 600 ? body.substring(0, 600) + "..." : body));
        }
        return r;
    }

    public static UUID id(Response r, String jsonPath) {
        String v = r.jsonPath().getString(jsonPath);
        if (v == null) {
            fail("no '" + jsonPath + "' in " + r.asString());
        }
        return UUID.fromString(v);
    }
}
