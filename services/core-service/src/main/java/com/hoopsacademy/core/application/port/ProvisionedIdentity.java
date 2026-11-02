package com.hoopsacademy.core.application.port;

/**
 * Result of provisioning: the subject of the login and whether this call created it (only created logins get a
 * temporary password and are deleted by compensations; an existing login belongs to someone else's history and keeps
 * its password).
 */
public record ProvisionedIdentity(String subject, boolean created) {}
