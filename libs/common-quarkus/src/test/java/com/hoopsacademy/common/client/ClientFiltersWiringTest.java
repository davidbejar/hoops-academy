package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.enterprise.inject.Instance;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

/** REST clients look this provider up as a CDI bean; it must be resolvable with the service's OIDC client config. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class ClientFiltersWiringTest {

    @Inject
    Instance<ServiceTokenClientFilter> serviceTokenFilter;

    @Test
    void theServiceTokenFilterIsAResolvableBean() {
        assertThat(serviceTokenFilter.isResolvable()).isTrue();
        assertThat(serviceTokenFilter.get()).isNotNull();
    }
}
