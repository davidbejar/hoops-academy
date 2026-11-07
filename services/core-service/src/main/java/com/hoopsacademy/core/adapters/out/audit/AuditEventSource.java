package com.hoopsacademy.core.adapters.out.audit;

/**
 * The two reads of {@code core.audit_event e} (SD-05 of the 2026-11 review): the SQL fragments are constants of this
 * closed type, so {@link AuditEventQueryRepository} cannot be handed any other text to splice into its query.
 */
public enum AuditEventSource {

    /** The bound tenant's own trail (core_app, RLS). */
    TENANT("", "from core.audit_event e"),
    /** Every academy's trail (core_platform), with the academy's name as a tenth column. */
    PLATFORM(", t.name", "from core.audit_event e join core.tenant t on t.id = e.tenant_id");

    private final String extraColumns;
    private final String from;

    AuditEventSource(String extraColumns, String from) {
        this.extraColumns = extraColumns;
        this.from = from;
    }

    String columns() {
        return AuditEventQueryRepository.COLUMNS + extraColumns;
    }

    String from() {
        return from;
    }
}
