package com.hoopsacademy.core.application.shared;

import com.hoopsacademy.core.domain.shared.Patch;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The names (never the values) of the fields a merge-patch touches — audit metadata without personal data. */
public final class ChangedFields {

    private final Map<String, Patch<?>> fields = new LinkedHashMap<>();

    public ChangedFields field(String name, Patch<?> patch) {
        fields.put(name, patch);
        return this;
    }

    public List<String> names() {
        return fields.entrySet().stream().filter(entry -> entry.getValue().isPresent()).map(Map.Entry::getKey)
                .sorted().toList();
    }
}
