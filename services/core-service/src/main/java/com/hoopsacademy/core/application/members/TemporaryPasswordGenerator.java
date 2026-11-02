package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import jakarta.enterprise.context.ApplicationScoped;
import java.security.SecureRandom;
import java.util.Random;

/**
 * Generates temporary passwords (ADR-0024): {@value #LENGTH} characters drawn uniformly by a {@link SecureRandom} from
 * an alphabet of 57 without look-alikes ({@code 0 O 1 l I}) or {@code @} (about 93 bits), with at least one upper-case
 * letter, one lower-case letter and one digit (draws without all three are discarded, which keeps the remaining ones
 * uniform). Meets the realm policy {@code length(12) and maxLength(128) and notUsername and notEmail}.
 */
@ApplicationScoped
public class TemporaryPasswordGenerator {

    static final int LENGTH = 16;
    static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789";

    private final Random random;

    TemporaryPasswordGenerator() {
        this(new SecureRandom());
    }

    /** For tests only: a reproducible source of randomness. */
    TemporaryPasswordGenerator(Random random) {
        this.random = random;
    }

    public TemporaryPassword next() {
        char[] candidate = new char[LENGTH];
        do {
            for (int i = 0; i < LENGTH; i++) {
                candidate[i] = ALPHABET.charAt(random.nextInt(ALPHABET.length()));
            }
        } while (!mixed(candidate));
        return TemporaryPassword.of(new String(candidate));
    }

    private static boolean mixed(char[] candidate) {
        boolean upper = false;
        boolean lower = false;
        boolean digit = false;
        for (char c : candidate) {
            upper |= Character.isUpperCase(c);
            lower |= Character.isLowerCase(c);
            digit |= Character.isDigit(c);
        }
        return upper && lower && digit;
    }
}
