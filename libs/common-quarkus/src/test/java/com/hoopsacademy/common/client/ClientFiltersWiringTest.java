package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.enterprise.inject.Instance;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

/** REST clients look these providers up as CDI beans; they must be resolvable with the service's OIDC client config. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class ClientFiltersWiringTest {

    @Inject
    Instance<ServiceTokenClientFilter> serviceTokenFilter;

    @Inject
    Instance<TenantHeaderPropagationFilter> tenantHeaderFilter;

    @Test
    void filtersAreResolvableBeans() {
        assertThat(serviceTokenFilter.isResolvable()).isTrue();
        assertThat(serviceTokenFilter.get()).isNotNull();
        assertThat(tenantHeaderFilter.get()).isNotNull();
    }
}
