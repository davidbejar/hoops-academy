package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.junit.callback.QuarkusTestAfterEachCallback;
import io.quarkus.test.junit.callback.QuarkusTestBeforeEachCallback;
import io.quarkus.test.junit.callback.QuarkusTestMethodContext;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.platform.commons.support.AnnotationSupport;

/** Translates {@link TenantUser} on the running test into a {@link TenantUserRegistry} membership. */
public class TenantUserCallback implements QuarkusTestBeforeEachCallback, QuarkusTestAfterEachCallback {

    @Override
    public void beforeEach(QuarkusTestMethodContext context) {
        TenantUserRegistry.clear();
        findTenantUser(context.getTestMethod()).map(TenantUserCallback::toMembership).ifPresent(TenantUserRegistry::register);
    }

    @Override
    public void afterEach(QuarkusTestMethodContext context) {
        TenantUserRegistry.clear();
    }

    static Optional<TenantUser> findTenantUser(Method testMethod) {
        return AnnotationSupport.findAnnotation(testMethod, TenantUser.class)
                .or(() -> AnnotationSupport.findAnnotation(testMethod.getDeclaringClass(), TenantUser.class));
    }

    static AuthzContext toMembership(TenantUser user) {
        TenantId tenantId = TenantId.parse(user.tenant());
        Set<TenantRole> roles = user.roles().length == 0
                ? Set.of()
                : EnumSet.copyOf(Arrays.asList(user.roles()));
        return new AuthzContext(
                TenantUser.SUBJECT,
                user.personId().isBlank() ? defaultPersonId(tenantId) : UUID.fromString(user.personId()),
                tenantId,
                roles,
                uuids(user.staffTeams()),
                uuids(user.linkedPlayers()),
                user.ownPlayer().isBlank() ? Optional.empty() : Optional.of(UUID.fromString(user.ownPlayer())),
                uuids(user.playerTeams()),
                user.timezone().isBlank() ? Optional.empty() : Optional.of(java.time.ZoneId.of(user.timezone())));
    }

    /** Stable person id per tenant so tests can predict it: {@code personIdFor(tenant)}. */
    public static UUID defaultPersonId(TenantId tenantId) {
        return UUID.nameUUIDFromBytes((TenantUser.SUBJECT + "@" + tenantId).getBytes(StandardCharsets.UTF_8));
    }

    private static Set<UUID> uuids(String[] raw) {
        return Arrays.stream(raw).map(UUID::fromString).collect(Collectors.toUnmodifiableSet());
    }
}
