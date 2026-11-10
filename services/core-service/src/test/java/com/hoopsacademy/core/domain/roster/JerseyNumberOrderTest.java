package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/** WP96: the taken numbers of a team are listed by value, a leading zero after the plain number. */
class JerseyNumberOrderTest {

    @Test
    void numbersSortByValueThenByLength() {
        List<String> sorted = Stream.of("10", "07", "8", "00", "7", "0", "99", "09", "9")
                .map(JerseyNumber::of).sorted().map(JerseyNumber::value).toList();

        assertThat(sorted).containsExactly("0", "00", "7", "07", "8", "9", "09", "10", "99");
    }

    @Test
    void equalNumbersCompareEqual() {
        assertThat(JerseyNumber.of("07").compareTo(JerseyNumber.of("07"))).isZero();
        assertThat(JerseyNumber.of("7").compareTo(JerseyNumber.of("07"))).isNegative();
        assertThat(JerseyNumber.of("07").compareTo(JerseyNumber.of("7"))).isPositive();
        assertThat(JerseyNumber.of("10").compareTo(JerseyNumber.of("9"))).isPositive();
    }
}
