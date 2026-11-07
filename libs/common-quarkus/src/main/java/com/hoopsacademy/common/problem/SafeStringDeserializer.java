package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.deser.std.StringDeserializer;
import java.io.IOException;

/** Jackson's own {@code String} reading, refusing NUL (SD-02): every request body field, list element and map value. */
final class SafeStringDeserializer extends StringDeserializer {

    @Override
    public String deserialize(JsonParser parser, DeserializationContext context) throws IOException {
        String text = super.deserialize(parser, context);
        if (UnsafeText.containsNul(text)) {
            throw new UnsafeTextException(parser);
        }
        return text;
    }
}
