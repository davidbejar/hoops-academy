package com.hoopsacademy.core.application.port;

/** A login moving to a new e-mail address (the username follows the e-mail, ADR-0023). */
public record LoginUpdate(String subject, String email, String givenName, String familyName) {}
