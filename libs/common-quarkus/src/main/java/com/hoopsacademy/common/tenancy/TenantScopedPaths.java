package com.hoopsacademy.common.tenancy;

import java.util.Collection;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Path convention: only {@code /api/**} is tenant scoped ({@code /platform}, {@code /internal}, {@code /q} are not),
 * except the exact paths listed in {@code hoops.tenancy.exempt-paths} (default {@code /api/core/me}, which lists the
 * caller's tenants and therefore cannot carry one). Paths are compared without leading/trailing slashes.
 */
final class TenantScopedPaths {

    private static final String API_SEGMENT = "api";

    private final Set<String> exempt;

    TenantScopedPaths(Collection<String> exemptPaths) {
        // a blank entry normalises to "", which is never tenant scoped anyway: no filter needed
        this.exempt = exemptPaths.stream().map(TenantScopedPaths::normalise).collect(Collectors.toUnmodifiableSet());
    }

    boolean isTenantScoped(String path) {
        String relative = normalise(path);
        boolean api = relative.equals(API_SEGMENT) || relative.startsWith(API_SEGMENT + "/");
        return api && !exempt.contains(relative);
    }

    private static String normalise(String path) {
        String trimmed = path.strip();
        int start = 0;
        int end = trimmed.length();
        while (start < end && trimmed.charAt(start) == '/') {
            start++;
        }
        while (end > start && trimmed.charAt(end - 1) == '/') {
            end--;
        }
        return trimmed.substring(start, end);
    }
}
