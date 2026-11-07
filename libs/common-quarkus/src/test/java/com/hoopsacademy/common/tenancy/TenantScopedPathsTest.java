package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Which paths need {@code X-Tenant-Id} (PIT scope, WP88; the filter itself is tested in TenantHeaderFilterTest). */
class TenantScopedPathsTest {

    private final TenantScopedPaths paths = new TenantScopedPaths(List.of(" /api/core/me/ ", "api/x", "", "/"));

    @ParameterizedTest
    @ValueSource(strings = {"/api", "api", "/api/", "/api/core/members", "//api/core/members//", " /api/x/y "})
    void apiPathsAreTenantScoped(String path) {
        assertThat(paths.isTenantScoped(path)).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {"/platform/x", "/internal/roster", "/q/health", "/apiary", "/", "", "///", "/v1/api"})
    void everyOtherPathIsNot(String path) {
        assertThat(paths.isTenantScoped(path)).isFalse();
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/core/me", "api/core/me", "/api/core/me/", "api/x/", " /api/x "})
    void exemptPathsAreComparedWithoutSurroundingSlashesAndBlanks(String path) {
        assertThat(paths.isTenantScoped(path)).isFalse();
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/core/me/details", "/api/core/m"})
    void anExemptionCoversItsExactPathOnly(String path) {
        assertThat(paths.isTenantScoped(path)).isTrue();
    }
}
