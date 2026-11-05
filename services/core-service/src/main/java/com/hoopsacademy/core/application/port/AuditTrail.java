package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;

/** Reads the bound tenant's audit trail (core_app, under RLS), newest first. */
public interface AuditTrail {

    PageResult<AuditRecord> list(AuditFilter filter, PageRequest page);
}
