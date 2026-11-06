package com.hoopsacademy.core.application.members;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Random;
import java.util.Locale;
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
    void discardsEveryDrawThatMissesACharacterClass() {
        int upper = TemporaryPasswordGenerator.ALPHABET.indexOf('A');
        int lower = TemporaryPasswordGenerator.ALPHABET.indexOf('a');
        int digit = TemporaryPasswordGenerator.ALPHABET.indexOf('2');
        Random scripted = new ScriptedRandom(
                draw(lower, digit),  // no upper-case letter
                draw(upper, digit),  // no lower-case letter
                draw(upper, lower),  // no digit
                draw(upper, lower, digit));

        assertThat(new TemporaryPasswordGenerator(scripted).next().reveal()).isEqualTo("A".repeat(14) + "a2");
    }

    /** One candidate: the given alphabet indexes at the end, padded in front with the first of them. */
    private static int[] draw(int... tail) {
        int[] indexes = new int[TemporaryPasswordGenerator.LENGTH];
        Arrays.fill(indexes, tail[0]);
        System.arraycopy(tail, 0, indexes, indexes.length - tail.length, tail.length);
        return indexes;
    }

    /** Answers nextInt with the scripted alphabet indexes, candidate after candidate. */
    private static final class ScriptedRandom extends Random {
        private final ArrayDeque<Integer> indexes = new ArrayDeque<>();

        ScriptedRandom(int[]... candidates) {
            for (int[] candidate : candidates) {
                for (int index : candidate) {
                    indexes.add(index);
                }
            }
        }

        @Override
        public int nextInt(int bound) {
            return indexes.removeFirst();
        }
    }

    @Test
    void neverDrawsAPasswordOfTheRealmBlocklist() throws IOException {
        // Keycloak lower-cases the candidate before the lookup (ADR-0038)
        Set<String> blocked = new HashSet<>(Files.readAllLines(blocklist(), StandardCharsets.UTF_8));
        assertThat(blocked).isNotEmpty();

        assertThat(IntStream.range(0, 100_000).mapToObj(i -> generator.next().reveal().toLowerCase(Locale.ROOT))
                .filter(blocked::contains)).isEmpty();
    }

    private static Path blocklist() {
        String relative = "infra/keycloak/password-blocklist/hoops-password-blocklist.txt";
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            if (Files.exists(dir.resolve(relative))) {
                return dir.resolve(relative);
            }
        }
        throw new AssertionError(relative + " not found");
    }

    @Test
    void theAlphabetHasNoLookAlikes() {
        assertThat(TemporaryPasswordGenerator.ALPHABET).doesNotContain("0", "O", "1", "l", "I", "@");
        assertThat(TemporaryPasswordGenerator.ALPHABET.chars().distinct().count())
                .isEqualTo(TemporaryPasswordGenerator.ALPHABET.length());
    }
}
