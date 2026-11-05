package com.hoopsacademy.core.application.audit;

/** An audit entry of the platform-wide trail and the name of its academy. */
public record PlatformAuditEntry(AuditEntry entry, String tenantName) {}
