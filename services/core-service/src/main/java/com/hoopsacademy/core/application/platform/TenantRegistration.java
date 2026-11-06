package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.events.TenantEvents;
import com.hoopsacademy.core.application.port.PlatformOutboxWriter;
import com.hoopsacademy.core.application.port.SubscriptionRepository;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

/**
 * Platform-datasource steps of onboarding: the registry row + subscription, and their compensation, which publishes
 * {@code tenant.removed} (WP81: every deletion publishes a removal, even of a tenant no consumer may have seen).
 */
@ApplicationScoped
public class TenantRegistration {

    private final TenantRepository tenants;
    private final SubscriptionRepository subscriptions;
    private final PlatformOutboxWriter outbox;

    public TenantRegistration(TenantRepository tenants, SubscriptionRepository subscriptions,
            PlatformOutboxWriter outbox) {
        this.tenants = tenants;
        this.subscriptions = subscriptions;
        this.outbox = outbox;
    }

    @Transactional
    public void requireSlugAvailable(TenantSlug slug) {
        if (tenants.slugExists(slug)) {
            throw new ConflictException("Slug '" + slug + "' is already taken", "SLUG_TAKEN");
        }
    }

    @Transactional
    public void register(Tenant tenant) {
        tenants.insert(tenant);
        subscriptions.subscribe(tenant.id(), SubscriptionRepository.DEFAULT_PLAN);
    }

    @Transactional
    public void unregister(TenantId tenant) {
        subscriptions.deleteUnprovisioned(tenant);
        tenants.deleteUnprovisioned(tenant);
        outbox.write(TenantEvents.removed(tenant));
    }
}
