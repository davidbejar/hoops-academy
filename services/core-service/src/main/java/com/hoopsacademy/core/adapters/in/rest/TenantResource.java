package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.PatchBody;
import com.hoopsacademy.core.application.tenant.TenantProfileService;
import com.hoopsacademy.core.application.tenant.TenantSettingsService;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfileChanges;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.Set;

/** Academy profile and settings: any member reads (non-members never get here: 404), ADMIN writes. */
@Path("/api/core/tenant")
@Produces(MediaType.APPLICATION_JSON)
public class TenantResource {

    /** {@code UpdateTenantProfileRequest.clear} (ADR-0032). */
    private static final Set<String> PROFILE_CLEARABLE = Set.of("contactEmail", "websiteUrl");

    private final TenantProfileService profiles;
    private final TenantSettingsService settings;

    public TenantResource(TenantProfileService profiles, TenantSettingsService settings) {
        this.profiles = profiles;
        this.settings = settings;
    }

    @GET
    public TenantProfileDto profile() {
        return TenantProfileDto.of(profiles.get());
    }

    @PATCH
    @Consumes(MediaType.APPLICATION_JSON)
    @RequiresTenantRole(TenantRole.ADMIN)
    public TenantProfileDto updateProfile(@NotNull JsonNode body) {
        PatchBody patch = PatchBody.of(body, PROFILE_CLEARABLE);
        TenantProfileChanges changes = new TenantProfileChanges(
                patch.nonBlankText("name", 120),
                patch.parsed("timezone", Constraints::zone),
                patch.parsed("defaultLocale", AppLocale::fromCode),
                patch.email("contactEmail"),
                patch.parsed("websiteUrl", TenantResource::httpUrl));
        patch.validate();
        return TenantProfileDto.of(profiles.update(changes));
    }

    @GET
    @Path("/settings")
    public TenantSettingsDto settings() {
        return TenantSettingsDto.of(settings.get());
    }

    @PUT
    @Path("/settings")
    @Consumes(MediaType.APPLICATION_JSON)
    @RequiresTenantRole(TenantRole.ADMIN)
    public TenantSettingsDto replaceSettings(@Valid @NotNull TenantSettingsDto request) {
        return TenantSettingsDto.of(settings.replace(request.toDomain()));
    }

    /** Only absolute http(s) URLs (no javascript:, data: …) may be stored and later rendered as links. */
    private static String httpUrl(String value) {
        java.net.URI uri = java.net.URI.create(value);
        if (uri.getHost() == null || !("https".equals(uri.getScheme()) || "http".equals(uri.getScheme()))
                || value.length() > 2048) {
            throw new IllegalArgumentException("not an http(s) URL");
        }
        return value;
    }
}
