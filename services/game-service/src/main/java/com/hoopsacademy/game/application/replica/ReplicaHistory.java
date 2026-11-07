package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.List;

/** The replica's bookkeeping tables (ADR-0037): applied event ids per tenant and the global parked records. */
public interface ReplicaHistory {

    /** Every tenant the replica holds rows of (no tenant bound). */
    List<TenantId> tenants();

    /**
     * Deletes up to {@code limit} applied event ids recorded before {@code before}, in the tenant bound to the current
     * transaction; rows another transaction holds are skipped.
     *
     * @return how many were deleted (fewer than {@code limit}: nothing older is left)
     */
    int deleteAppliedBefore(Instant before, int limit);

    /** Deletes the parked records an operator inspected before {@code inspectedBefore} (no tenant bound). */
    List<ParkedPosition> deleteParkedInspectedBefore(Instant inspectedBefore);
}
