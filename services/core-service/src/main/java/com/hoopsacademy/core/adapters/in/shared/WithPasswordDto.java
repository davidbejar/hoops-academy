package com.hoopsacademy.core.adapters.in.shared;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonUnwrapped;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.util.function.Function;

/**
 * Contract {@code TenantWithPassword}, {@code TenantAdminWithPassword}, {@code MemberWithPassword},
 * {@code ApprovalRequestWithPassword}: the body's own fields plus {@code temporaryPassword} (ADR-0024), present only
 * when the call created or re-issued a login's password. The only place the value leaves the service; responses that
 * may carry it are sent with {@value #NO_STORE} (see {@link #noStore}).
 */
public record WithPasswordDto<T>(
        @JsonUnwrapped T body,
        @JsonInclude(JsonInclude.Include.NON_NULL) String temporaryPassword) {

    public static final String NO_STORE = "no-store";

    public static <S, T> WithPasswordDto<T> of(WithTemporaryPassword<S> result, Function<S, T> toDto) {
        return new WithPasswordDto<>(toDto.apply(result.value()),
                result.temporaryPassword().map(TemporaryPassword::reveal).orElse(null));
    }

    /** Marks a response that may carry a temporary password as never cacheable. */
    public static Response.ResponseBuilder noStore(Response.ResponseBuilder response) {
        return response.header(HttpHeaders.CACHE_CONTROL, NO_STORE);
    }

    @Override
    public String toString() {
        return "WithPasswordDto[body=" + body + ", temporaryPassword=" + (temporaryPassword == null ? "none" : "***")
                + "]";
    }
}
