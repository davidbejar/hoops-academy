package com.hoopsacademy.core.application.me;

/** The authenticated caller as /me needs it (taken from the access token by the REST adapter). */
public record Caller(String subject, boolean superAdmin, String email, String displayName) {}
