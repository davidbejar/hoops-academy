package com.hoopsacademy.e2e.support;

import java.util.LinkedHashMap;
import java.util.Map;

/** Terse map builder for request bodies. */
public final class Json {
    private Json() {}

    public static Map<String, Object> of(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            m.put((String) kv[i], kv[i + 1]);
        }
        return m;
    }
}
