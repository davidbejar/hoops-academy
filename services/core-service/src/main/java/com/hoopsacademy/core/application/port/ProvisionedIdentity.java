package com.hoopsacademy.core.application.port;

/**
 * Result of provisioning: the subject of the login and whether this call created it (only created logins are
 * sent the setup e-mail and deleted by compensations; an existing login belongs to someone else's history).
 */
public record ProvisionedIdentity(String subject, boolean created) {}
