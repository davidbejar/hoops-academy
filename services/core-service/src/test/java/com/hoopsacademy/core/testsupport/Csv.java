package com.hoopsacademy.core.testsupport;

import static org.assertj.core.api.Assertions.assertThat;

import io.restassured.response.Response;
import java.nio.charset.StandardCharsets;
import java.util.List;

/** The CSV exports as a test reads them (ADR-0048): UTF-8 with a byte order mark, CRLF line ends. */
public final class Csv {

    private Csv() {}

    /** The lines of a 200 answer, after checking and dropping the byte order mark. */
    public static List<String> lines(Response response) {
        String csv = new String(response.then().statusCode(200).extract().asByteArray(), StandardCharsets.UTF_8);
        assertThat(csv).startsWith("﻿");
        return List.of(csv.substring(1).split("\r\n"));
    }
}
