package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.deser.std.JsonNodeDeserializer;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import com.fasterxml.jackson.databind.node.NullNode;
import java.io.IOException;

/** Jackson's own {@code JsonNode} reading, refusing NUL anywhere in the tree (SD-02): the PATCH bodies and event batches. */
final class SafeTreeDeserializer extends StdDeserializer<JsonNode> {

    private static final long serialVersionUID = 1L;

    SafeTreeDeserializer() {
        super(JsonNode.class);
    }

    @Override
    public JsonNode deserialize(JsonParser parser, DeserializationContext context) throws IOException {
        JsonNode node = JsonNodeDeserializer.getDeserializer(JsonNode.class).deserialize(parser, context);
        var nul = UnsafeText.nulPathIn(node);
        if (nul.isPresent()) {
            throw new UnsafeTextException(parser, nul.get());
        }
        return node;
    }

    @Override
    public JsonNode getNullValue(DeserializationContext context) {
        return NullNode.getInstance();
    }
}
