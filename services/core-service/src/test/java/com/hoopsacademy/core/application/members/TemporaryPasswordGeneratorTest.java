package com.hoopsacademy.core.application.members;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import java.util.HashSet;
import java.util.Random;
import java.util.Set;
import java.util.stream.IntStream;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.Test;

class TemporaryPasswordGeneratorTest {

    private final TemporaryPasswordGenerator generator = new TemporaryPasswordGenerator();

    @RepeatedTest(200)
    void satisfiesTheRealmPolicyWithMixedClassesFromAnUnambiguousAlphabet() {
        String value = generator.next().reveal();

        assertThat(value).hasSize(TemporaryPasswordGenerator.LENGTH)
                .matches("[" + TemporaryPasswordGenerator.ALPHABET + "]+")
                .doesNotContain("@")
                .containsPattern("[A-Z]").containsPattern("[a-z]").containsPattern("[2-9]")
                .doesNotContainPattern("[0O1lI]");
        assertThat(value.length()).isBetween(TemporaryPassword.MIN_LENGTH, TemporaryPassword.MAX_LENGTH);
    }

    @Test
    void neverRepeatsItselfAcrossManyDraws() {
        Set<String> seen = new HashSet<>();
        IntStream.range(0, 10_000).forEach(i -> seen.add(generator.next().reveal()));
        assertThat(seen).hasSize(10_000);
    }

    @Test
    void everyAlphabetCharacterIsUsedRoughlyEvenly() {
        int[] counts = new int[128];
        int draws = 5_000;
        IntStream.range(0, draws).forEach(i -> generator.next().reveal().chars().forEach(c -> counts[c]++));
        double expected = (double) draws * TemporaryPasswordGenerator.LENGTH / TemporaryPasswordGenerator.ALPHABET.length();
        for (char c : TemporaryPasswordGenerator.ALPHABET.toCharArray()) {
            assertThat(counts[c]).as("occurrences of '%s'", c).isBetween((int) (expected * 0.75), (int) (expected * 1.25));
        }
    }

    @Test
    void usesTheInjectedSourceOfRandomness() {
        assertThat(new TemporaryPasswordGenerator(new Random(7)).next())
                .isEqualTo(new TemporaryPasswordGenerator(new Random(7)).next());
    }

    @Test
    void theAlphabetHasNoLookAlikes() {
        assertThat(TemporaryPasswordGenerator.ALPHABET).doesNotContain("0", "O", "1", "l", "I", "@");
        assertThat(TemporaryPasswordGenerator.ALPHABET.chars().distinct().count())
                .isEqualTo(TemporaryPasswordGenerator.ALPHABET.length());
    }
}
