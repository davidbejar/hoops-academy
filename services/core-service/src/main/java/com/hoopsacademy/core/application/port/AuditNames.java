package com.hoopsacademy.core.application.port;

import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Display names for the audit trail, read in the bound tenant (core_app, RLS): ids of other tenants and rows that no
 * longer exist are simply absent from the result.
 */
public interface AuditNames {

    /** Given and family name of these persons (active or not). */
    Map<UUID, String> persons(Set<UUID> ids);

    /** Name of the person of these players. */
    Map<UUID, String> players(Set<UUID> ids);

    /** Name of the academy (only the bound one is visible). */
    Map<UUID, String> tenants(Set<UUID> ids);

    /** Given and family name of those of these persons who are active administrators (ADR-0023 identity). */
    Map<UUID, String> activeAdmins(Set<UUID> ids);
}
