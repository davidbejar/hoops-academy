package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.common.authz.MembershipReads;
import com.hoopsacademy.common.authz.MembershipRule;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.Optional;

/**
 * The tenant filter's membership from the replica (hoops.roster.source=replica): common's {@link MembershipRule}
 * (ADR-0066, the rule of core's {@code /internal/authz}) over the replica's reads. Called with the requested tenant
 * bound, so every read is RLS-scoped.
 */
@ApplicationScoped
@Typed(ReplicaAuthzResolver.class)
public class ReplicaAuthzResolver implements AuthzContextResolver {

    private final MembershipReads reads;
    private final Clock clock;

    public ReplicaAuthzResolver(MembershipReads reads, Clock clock) {
        this.reads = reads;
        this.clock = clock;
    }

    @Override
    @Transactional
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return MembershipRule.resolve(subject, tenantId, reads, clock);
    }
}
