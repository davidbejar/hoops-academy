package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.CallerIdentity;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.application.me.GetMe;
import com.hoopsacademy.core.domain.shared.AppLocale;
import io.quarkus.security.Authenticated;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

/**
 * {@code GET|PATCH /api/core/me}. No tenant header: the path is in common-quarkus' {@code hoops.tenancy.exempt-paths}
 * (library default), so the tenant filter skips it; authentication is required by {@code @Authenticated}.
 */
@Path(MeResource.PATH)
@Authenticated
@Produces(MediaType.APPLICATION_JSON)
public class MeResource {

    static final String PATH = "/api/core/me";

    /** Contract {@code UpdateMeRequest}. */
    public record UpdateMeRequest(@NotNull @Pattern(regexp = Constraints.LOCALE) String locale) {}

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
    public MeDto update(@Valid @NotNull UpdateMeRequest request) {
        return MeDto.of(getMe.changeLocale(caller.current(), AppLocale.fromCode(request.locale())));
    }
}
