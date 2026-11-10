package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.InvalidRequestException;
import com.hoopsacademy.core.adapters.in.shared.PatchBody;
import com.hoopsacademy.core.application.me.GetMe;
import com.hoopsacademy.core.application.me.MeChanges;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import io.quarkus.security.Authenticated;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.Optional;

/**
 * {@code GET|PATCH /api/core/me}. No tenant header: the path is in common-quarkus' {@code hoops.tenancy.exempt-paths}
 * (library default), so the tenant filter skips it; authentication is required by {@code @Authenticated}.
 */
@Path(MeResource.PATH)
@Authenticated
@Produces(MediaType.APPLICATION_JSON)
public class MeResource {

    static final String PATH = "/api/core/me";
    private static final String LOCALE = "locale";
    private static final String GIVEN_NAME = "givenName";
    private static final String FAMILY_NAME = "familyName";
    private static final String TENANT_ID = "tenantId";

    /** Contract {@code UpdateMeRequest} (core 3.4.0: every member optional, no e-mail). */
    private static final String[] UPDATE_MEMBERS = {LOCALE, GIVEN_NAME, FAMILY_NAME, TENANT_ID};
    private static final int NAME_MAX = 80;

    private final GetMe getMe;
    private final CallerIdentity caller;

    public MeResource(GetMe getMe, CallerIdentity caller) {
        this.getMe = getMe;
        this.caller = caller;
    }

    @GET
    public MeDto get() {
        return MeDto.of(getMe.handle(caller.current()));
    }

    @PATCH
    @Consumes(MediaType.APPLICATION_JSON)
    public MeDto update(@NotNull JsonNode body) {
        return MeDto.of(getMe.update(caller.current(), changes(body)));
    }

    /**
     * The language, and the own name with the validation of {@code updateMember}; a name needs the academy
     * ({@code tenantId}) and the academy needs a name (400 otherwise). Any other member, the e-mail included, is a 400.
     */
    private static MeChanges changes(JsonNode body) {
        PatchBody patch = PatchBody.of(body);
        patch.allowOnly(UPDATE_MEMBERS);
        Patch<AppLocale> locale = patch.parsed(LOCALE, AppLocale::fromCode);
        Patch<String> givenName = patch.nonBlankText(GIVEN_NAME, NAME_MAX);
        Patch<String> familyName = patch.nonBlankText(FAMILY_NAME, NAME_MAX);
        Patch<TenantId> tenant = patch.parsed(TENANT_ID, TenantId::parse);
        patch.validate();
        boolean renames = givenName.isPresent() || familyName.isPresent();
        if (renames != tenant.isPresent()) {
            throw InvalidRequestException.of(TENANT_ID, renames ? "is required with givenName or familyName"
                    : "is only accepted with givenName or familyName");
        }
        return new MeChanges(Optional.ofNullable(locale.applyTo(null)), renames
                ? Optional.of(new MeChanges.OwnName(tenant.applyTo(null), givenName, familyName))
                : Optional.empty());
    }
}
