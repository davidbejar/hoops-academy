package com.hoopsacademy.core.domain.roster;

import java.util.Objects;

/** The number a new assignment gets ({@code null} for none) and the rule that chose it. */
public record JerseyChoice(JerseyNumber number, JerseySource source) {

    public static final JerseyChoice NONE = new JerseyChoice(null, JerseySource.NONE);

    public JerseyChoice {
        Objects.requireNonNull(source, "source");
    }
}
