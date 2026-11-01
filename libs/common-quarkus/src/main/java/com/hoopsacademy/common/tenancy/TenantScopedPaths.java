package com.hoopsacademy.common.tenancy;

/** Path convention: only {@code /api/**} is tenant scoped ({@code /platform}, {@code /internal}, {@code /q} are not). */
final class TenantScopedPaths {

    private static final String API_SEGMENT = "api";

    private TenantScopedPaths() {}

    static boolean isTenantScoped(String path) {
        String relative = path.startsWith("/") ? path.substring(1) : path;
        return relative.equals(API_SEGMENT) || relative.startsWith(API_SEGMENT + "/");
    }
}
