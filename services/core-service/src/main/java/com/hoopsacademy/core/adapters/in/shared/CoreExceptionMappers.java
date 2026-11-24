package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.common.problem.ProblemType;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.domain.logo.LogoTooLargeException;
import com.hoopsacademy.core.domain.logo.UnsupportedLogoFormatException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Problem+JSON for the failures specific to core (401, 409 lost updates, 503 come from the common-quarkus mappers). */
public class CoreExceptionMappers {

    private static final Logger LOG = Logger.getLogger(CoreExceptionMappers.class);

    @ServerExceptionMapper
    public Response identityProvider(IdentityProviderException e, UriInfo uri) {
        LOG.errorf(e, "Identity provider failure on %s", uri.getPath());
        return problem(ProblemType.IDENTITY_PROVIDER_UNAVAILABLE,
                "The identity provider is unavailable; nothing was changed", "IDENTITY_PROVIDER_UNAVAILABLE", uri);
    }

    @ServerExceptionMapper
    public Response logoTooLarge(LogoTooLargeException e, UriInfo uri) {
        return problem(ProblemType.PAYLOAD_TOO_LARGE, e.getMessage(), "LOGO_TOO_LARGE", uri);
    }

    @ServerExceptionMapper
    public Response unsupportedLogo(UnsupportedLogoFormatException e, UriInfo uri) {
        return problem(ProblemType.UNSUPPORTED_MEDIA_TYPE, e.getMessage(), "UNSUPPORTED_IMAGE_FORMAT", uri);
    }

    private static Response problem(ProblemType type, String detail, String code, UriInfo uri) {
        return Problem.of(type, detail, uri.getRequestUri().getRawPath(), code, List.of()).toResponse();
    }
}
