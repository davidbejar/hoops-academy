package com.hoopsacademy.core.testsupport;

import static io.restassured.RestAssured.given;

import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.util.UUID;

/** REST calls of the players / approval-requests API with contract validation, for the approval test suites. */
public final class Approvals {

    private final String tenant;

    public Approvals(String tenant) {
        this.tenant = tenant;
    }

    public RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    /** For requests the contract forbids on purpose (invalid bodies / parameters); responses are still validated. */
    public RequestSpecification lenientRequest() {
        return given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant);
    }

    /** A body for POST /players: an 11-year-old (born mid-year) of the given name. */
    public static String playerJson(String name, String gender, int age, String extra) {
        return "{\"givenName\":\"" + name + "\",\"familyName\":\"Test\",\"birthDate\":\"" + (RosterDb.YEAR - age)
                + "-06-15\",\"gender\":\"" + gender + "\"" + extra + "}";
    }

    public ValidatableResponse create(String json) {
        return request().contentType(ContentType.JSON).body(json).post("/api/core/players").then();
    }

    public ValidatableResponse withdraw(UUID player) {
        return request().contentType(ContentType.JSON).body("{\"reason\":\"moved away\"}")
                .post("/api/core/players/" + player + "/withdraw").then();
    }

    public ValidatableResponse decide(UUID request, String verb, String note) {
        return request().contentType(ContentType.JSON).body(note == null ? "{}" : "{\"note\":\"" + note + "\"}")
                .post("/api/core/approval-requests/" + request + "/" + verb).then();
    }

    public ValidatableResponse cancel(UUID request) {
        return request().post("/api/core/approval-requests/" + request + "/cancel").then();
    }

    public ValidatableResponse getRequest(UUID request) {
        return request().get("/api/core/approval-requests/" + request).then();
    }

    public ValidatableResponse getPlayer(UUID player) {
        return request().get("/api/core/players/" + player).then();
    }

    public long outbox(String type) {
        return CoreDb.count(tenant, "select count(*) from core.outbox where event_type = ?", type);
    }
}
