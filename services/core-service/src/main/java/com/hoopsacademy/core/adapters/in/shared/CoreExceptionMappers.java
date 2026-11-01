package com.hoopsacademy.core.adapters.in.shared;

import com.hoopsacademy.common.problem.Problem;
import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.domain.logo.LogoTooLargeException;
import com.hoopsacademy.core.domain.logo.UnsupportedLogoFormatException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

/** Problem+JSON for the failures specific to core (401, 409 lost updates, 503 come from the common-quarkus mappers). */
public class CoreExceptionMappers {

    private static final Logger LOG = Logger.getLogger(CoreExceptionMappers.class);

    @ServerExceptionMapper
    public Response identityProvider(IdentityProviderException e, UriInfo uri) {
        LOG.errorf(e, "Identity provider failure on %s", uri.getPath());
        return problem(502, "Bad Gateway", "identity-provider-unavailable",
                "The identity provider is unavailable; nothing was changed", "IDENTITY_PROVIDER_UNAVAILABLE", uri);
    }

    @ServerExceptionMapper
    public Response logoTooLarge(LogoTooLargeException e, UriInfo uri) {
        return problem(413, "Payload Too Large", "payload-too-large", e.getMessage(), "LOGO_TOO_LARGE", uri);
    }

    @ServerExceptionMapper
    public Response unsupportedLogo(UnsupportedLogoFormatException e, UriInfo uri) {
        return problem(415, "Unsupported Media Type", "unsupported-media-type", e.getMessage(),
                "UNSUPPORTED_IMAGE_FORMAT", uri);
    }

    @ServerExceptionMapper
    public Response invalidRequest(InvalidRequestException e, UriInfo uri) {
        return Problem.validation(e.violations(), path(uri)).toResponse();
    }

    private static Response problem(int status, String title, String slug, String detail, String code, UriInfo uri) {
        return new Problem("urn:hoops:problem:" + slug, title, status, detail, path(uri), null, code, null)
                .toResponse();
    }

    private static String path(UriInfo uri) {
        return uri.getRequestUri().getRawPath();
    }
}
