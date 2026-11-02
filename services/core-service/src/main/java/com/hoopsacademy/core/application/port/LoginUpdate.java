package com.hoopsacademy.core.application.port;

/**
 * A login moving to a new e-mail address (the username follows the e-mail, ADR-0023).
 *
 * @param setupPending the invitation is still pending: the new address gets the account-setup actions
 *                     (UPDATE_PASSWORD, VERIFY_EMAIL) instead of VERIFY_EMAIL only
 */
public record LoginUpdate(String subject, String email, String givenName, String familyName, boolean setupPending) {}
