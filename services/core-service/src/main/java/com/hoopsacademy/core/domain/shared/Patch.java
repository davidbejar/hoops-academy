package com.hoopsacademy.core.domain.shared;

/**
 * One field of a partial update (JSON merge-patch semantics): absent = keep the current value, present with a
 * value = replace, present with {@code null} = clear.
 */
public final class Patch<T> {

    private static final Patch<?> ABSENT = new Patch<>(false, null);

    private final boolean present;
    private final T value;

    private Patch(boolean present, T value) {
        this.present = present;
        this.value = value;
    }

    @SuppressWarnings("unchecked")
    public static <T> Patch<T> absent() {
        return (Patch<T>) ABSENT;
    }

    /** @param value the new value, or {@code null} to clear the field */
    public static <T> Patch<T> of(T value) {
        return new Patch<>(true, value);
    }

    public boolean isPresent() {
        return present;
    }

    /** True when the patch explicitly clears the field. */
    public boolean clears() {
        return present && value == null;
    }

    public T applyTo(T current) {
        return present ? value : current;
    }
}
