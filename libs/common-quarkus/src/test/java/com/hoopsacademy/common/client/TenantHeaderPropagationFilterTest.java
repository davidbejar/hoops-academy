package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.CurrentTenant;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.ws.rs.client.ClientRequestContext;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TenantHeaderPropagationFilterTest {

    private final CurrentTenant currentTenant = mock(CurrentTenant.class);
    private final ClientRequestContext request = mock(ClientRequestContext.class);
    private final MultivaluedMap<String, Object> headers = new MultivaluedHashMap<>();
    private final TenantHeaderPropagationFilter filter = new TenantHeaderPropagationFilter(currentTenant, "X-Tenant-Id");

    @BeforeEach
    void wireHeaders() {
        when(request.getHeaders()).thenReturn(headers);
    }

    @Test
    void propagatesTheBoundTenant() {
        TenantId tenant = TenantId.random();
        when(currentTenant.tenantId()).thenReturn(Optional.of(tenant));

        filter.filter(request);

        assertThat(headers.getFirst("X-Tenant-Id")).isEqualTo(tenant.toString());
    }

    @Test
    void addsNothingWithoutABoundTenant() {
        when(currentTenant.tenantId()).thenReturn(Optional.empty());

        filter.filter(request);

        assertThat(headers).isEmpty();
    }

    @Test
    void keepsAnExplicitlySetHeader() {
        when(currentTenant.tenantId()).thenReturn(Optional.of(TenantId.random()));
        headers.putSingle("X-Tenant-Id", "explicit");

        filter.filter(request);

        assertThat(headers.get("X-Tenant-Id")).containsExactly("explicit");
    }
}
