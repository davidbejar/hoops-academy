package com.hoopsacademy.core.application.shared;

import com.hoopsacademy.core.domain.membership.PersonalData;
import java.util.List;
import java.util.Objects;
import java.util.TreeSet;

/**
 * The names (never the values) of the fields an update really changes — audit metadata without personal data. A field
 * counts only when its stored value differs from the new one, so a PATCH that repeats the stored values, or clears a
 * field that is already empty, changes nothing: callers then write no audit row (WP58).
 */
public final class ChangedFields {

    private final TreeSet<String> names = new TreeSet<>();

    public static ChangedFields of(PersonalData before, PersonalData after) {
        return new ChangedFields()
                .field("givenName", before.givenName(), after.givenName())
                .field("familyName", before.familyName(), after.familyName())
                .field("email", before.email(), after.email())
                .field("phone", before.phone(), after.phone())
                .field("birthDate", before.birthDate(), after.birthDate())
                .field("gender", before.gender(), after.gender())
                .field("locale", before.locale(), after.locale());
    }

    public <T> ChangedFields field(String name, T before, T after) {
        if (!Objects.equals(before, after)) {
            names.add(name);
        }
        return this;
    }

    public boolean isEmpty() {
        return names.isEmpty();
    }

    /** Sorted by name. */
    public List<String> names() {
        return List.copyOf(names);
    }
}
