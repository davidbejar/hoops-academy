package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.paging.PageRequest;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Optional;

/**
 * Reads the audit trail of every academy (or of one) through the platform datasource, newest first, with the
 * academy's name from the registry (ADR-0029: core_platform's read policy on {@code core.audit_event}).
 */
public interface PlatformAuditTrail {

    record Row(AuditRecord record, String tenantName) {}

    PageResult<Row> list(Optional<TenantId> tenant, AuditFilter filter, PageRequest page);
}
