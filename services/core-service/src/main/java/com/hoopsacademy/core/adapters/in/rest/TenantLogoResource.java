package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.LogoRepository.StoredLogo;
import com.hoopsacademy.core.application.tenant.TenantLogoService;
import com.hoopsacademy.core.domain.logo.LogoImage;
import com.hoopsacademy.core.domain.logo.LogoTooLargeException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;

/**
 * Academy logo (ADR-0009). Upload: the declared Content-Type must be one of the three image types (else 415 from
 * JAX-RS), but the stored and served type is the one detected from the magic bytes; at most 512 KB are read.
 * Download: any member, strong ETag, {@code Cache-Control: private, max-age=86400}, 304 on If-None-Match.
 */
@Path("/api/core/tenant/logo")
public class TenantLogoResource {

    static final String CACHE_CONTROL = "private, max-age=86400";
    private static final String NOSNIFF = "nosniff";

    private final TenantLogoService logos;

    public TenantLogoResource(TenantLogoService logos) {
        this.logos = logos;
    }

    @GET
    @Produces({"image/png", "image/jpeg", "image/webp"})
    public Response get(@HeaderParam(HttpHeaders.IF_NONE_MATCH) String ifNoneMatch) {
        StoredLogo logo = logos.get();
        LogoImage image = logo.image();
        if (image.matches(ifNoneMatch)) {
            return Response.notModified().header(HttpHeaders.ETAG, image.etag()).build();
        }
        return Response.ok(image.bytes(), image.format().mediaType())
                .header(HttpHeaders.ETAG, image.etag())
                .header(HttpHeaders.CACHE_CONTROL, CACHE_CONTROL)
                .header("X-Content-Type-Options", NOSNIFF)
                .build();
    }

    @PUT
    @Consumes({"image/png", "image/jpeg", "image/webp"})
    @Produces(MediaType.APPLICATION_JSON)
    @RequiresTenantRole(TenantRole.ADMIN)
    public Response put(InputStream body) {
        StoredLogo stored = logos.upload(readAtMostLimit(body));
        return Response.ok(TenantLogoDto.of(stored)).header(HttpHeaders.ETAG, stored.image().etag()).build();
    }

    @DELETE
    @RequiresTenantRole(TenantRole.ADMIN)
    public void delete() {
        logos.delete();
    }

    /** Reads one byte past the limit at most, so an oversized body is rejected without buffering it whole. */
    private static byte[] readAtMostLimit(InputStream body) {
        try (body) {
            byte[] content = body.readNBytes(LogoImage.MAX_BYTES + 1);
            if (content.length > LogoImage.MAX_BYTES) {
                throw new LogoTooLargeException(LogoImage.MAX_BYTES);
            }
            return content;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
