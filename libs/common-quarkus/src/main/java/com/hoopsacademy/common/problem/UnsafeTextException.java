package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import java.util.List;

/** JSON text with a NUL character ({@link UnsafeText}); a 400 Problem naming the field. */
public class UnsafeTextException extends MismatchedInputException {

    static final String MESSAGE = "Text must not contain a NUL character";

    UnsafeTextException(JsonParser parser) {
        super(parser, MESSAGE, String.class);
    }

    /** A NUL inside a JSON tree at {@code path} (field names and indexes, outermost first). */
    UnsafeTextException(JsonParser parser, List<Object> path) {
        this(parser);
        for (int i = path.size() - 1; i >= 0; i--) {
            Object step = path.get(i);
            prependPath(step instanceof Integer index ? new Reference(null, index) : new Reference(null, (String) step));
        }
    }
}
