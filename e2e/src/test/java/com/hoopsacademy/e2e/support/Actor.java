package com.hoopsacademy.e2e.support;

import static io.restassured.RestAssured.given;

import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.util.UUID;

/** A signed-in user acting in one tenant. Every call validates its response against the service's OpenAPI. */
public final class Actor {
    public final String name;
    private final String token;
    private final UUID tenantId;

    public Actor(String name, String token, UUID tenantId) {
        this.name = name;
        this.token = token;
        this.tenantId = tenantId;
    }

    /** Same user, other tenant header (cross-tenant probes). */
    public Actor inTenant(UUID other) {
        return new Actor(name, token, other);
    }

    private RequestSpecification spec(String path, boolean validate) {
        RequestSpecification s = given().baseUri(E2eEnv.baseUrl()).auth().oauth2(token).accept("*/*");
        if (tenantId != null) {
            s.header("X-Tenant-Id", tenantId.toString());
        }
        var f = validate ? Contracts.forPath(path) : null;
        if (f != null) {
            s.filter(f);
        }
        return s;
    }

    public Response get(String path) {
        return spec(path, true).get(path);
    }

    public Response getUnvalidated(String path) {
        return spec(path, false).get(path);
    }

    public Response post(String path, Object body) {
        return spec(path, true).contentType(ContentType.JSON).body(body).post(path);
    }

    public Response post(String path) {
        return spec(path, true).post(path);
    }

    public Response put(String path, Object body) {
        return spec(path, true).contentType(ContentType.JSON).body(body).put(path);
    }

    public Response patch(String path, Object body) {
        return spec(path, true).contentType(ContentType.JSON).body(body).patch(path);
    }

    public Response delete(String path) {
        return spec(path, true).delete(path);
    }

    /** Raw request with an explicit body and no response validation (deliberately malformed / foreign payloads). */
    public Response postUnvalidated(String path, Object body) {
        return spec(path, false).contentType(ContentType.JSON).body(body).post(path);
    }
}
