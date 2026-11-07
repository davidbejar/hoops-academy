package com.hoopsacademy.game.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.application.SubmittedEvent;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import jakarta.enterprise.context.ApplicationScoped;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Validates one submitted event against libs/contracts events/match-event.schema.json (read from the contracts jar)
 * and maps it to the domain. Never throws for bad input: the event becomes {@link SubmittedEvent.Invalid}.
 */
@ApplicationScoped
public class MatchEventDecoder {

    static final String SCHEMA_RESOURCE = "/events/match-event.schema.json";
    private static final Pattern UUID_FORMAT =
            Pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private final Schema schema;

    public MatchEventDecoder(ObjectMapper mapper) {
        try (InputStream in = MatchEventDecoder.class.getResourceAsStream(SCHEMA_RESOURCE)) {
            // a build without the contracts jar fails at startup, naming the resource
            Objects.requireNonNull(in, SCHEMA_RESOURCE + " is not on the classpath (contracts jar)");
            this.schema = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12).getSchema(mapper.readTree(in));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    public SubmittedEvent decode(JsonNode json) {
        UUID id = idOf(json);
        List<Error> errors = schema.validate(json);
        if (!errors.isEmpty()) {
            return new SubmittedEvent.Invalid(id, errors.stream().limit(5)
                    .map(e -> e.getInstanceLocation() + ": " + e.getMessage()).collect(Collectors.joining("; ")));
        }
        try {
            return new SubmittedEvent.Valid(MatchEventJson.decode(json));
        } catch (RuntimeException e) {
            return new SubmittedEvent.Invalid(id, "Malformed event: " + e.getMessage());
        }
    }

    private static UUID idOf(JsonNode json) {
        String id = json.path("id").asText("");
        return UUID_FORMAT.matcher(id).matches() ? UUID.fromString(id) : SubmittedEvent.Invalid.NO_ID;
    }
}
