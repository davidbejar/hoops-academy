package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.AcademyNames;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/**
 * {@link AcademyNames} from the replica's tenant row, whatever {@code hoops.roster.source} says: core's
 * {@code /internal} API has no academy name, and the consumer feeds the replica in both modes (ADR-0037). Only
 * {@code rest} with the consumer switched off leaves it empty. Joins the caller's transaction, whose bound tenant must
 * be {@code tenantId} (RLS: another tenant's row is not visible).
 */
@ApplicationScoped
public class ReplicaAcademyNames implements AcademyNames {

    private final RosterReplicaQueries replica;

    public ReplicaAcademyNames(RosterReplicaQueries replica) {
        this.replica = replica;
    }

    @Override
    @Transactional
    public Optional<String> find(TenantId tenantId) {
        return replica.tenant(tenantId).flatMap(ReplicaTenant::knownName);
    }
}
