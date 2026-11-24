package com.hoopsacademy.contracts;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.parser.OpenAPIV3Parser;
import io.swagger.v3.parser.core.models.ParseOptions;
import io.swagger.v3.parser.core.models.SwaggerParseResult;

import java.lang.module.ModuleDescriptor;
import java.util.List;

/** Parses the service specifications with swagger-parser (the parser used by swagger-request-validator). */
final class OpenApiSpecs {

    static final List<String> SERVICES = List.of("core", "game", "athlete", "finance");

    private OpenApiSpecs() {
    }

    /** External refs resolved, component names kept (needed to compare named schemas). */
    static SwaggerParseResult parse(String service) {
        return parse(service, false);
    }

    /**
     * The spec's {@code info.version}, comparable: a feature test asserts the release that brought its feature as a
     * lower bound, so a later additive release of the spec does not fail it (LIB-12).
     */
    static ModuleDescriptor.Version version(String service) {
        return release(parse(service).getOpenAPI().getInfo().getVersion());
    }

    static ModuleDescriptor.Version release(String version) {
        return ModuleDescriptor.Version.parse(version);
    }

    /** Every $ref inlined (convenient to inspect responses and parameters). */
    static OpenAPI parseFullyResolved(String service) {
        return parse(service, true).getOpenAPI();
    }

    private static SwaggerParseResult parse(String service, boolean resolveFully) {
        ParseOptions options = new ParseOptions();
        options.setResolve(true);
        options.setResolveFully(resolveFully);
        return new OpenAPIV3Parser().readLocation(ContractFiles.openApi(service).toUri().toString(), null, options);
    }
}
