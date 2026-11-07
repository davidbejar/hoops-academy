package com.hoopsacademy.common.paging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** The row offset of a 0-based page never wraps around {@code int} (SD-01 of the 2026-11 review). */
class PageOffsetTest {

    @ParameterizedTest
    @CsvSource({"0, 1, 0", "0, 200, 0", "1, 50, 50", "3, 7, 21", "10737417, 200, 2147483400",
        "2147483447, 1, 2147483447", "1073741723, 2, 2147483446"})
    void anOffsetThatFitsIsPageTimesSize(int page, int size, int offset) {
        assertThat(PageOffset.of(page, size)).isEqualTo(offset);
    }

    @ParameterizedTest
    @CsvSource({"10737418, 200", "2147483647, 200", "2147483647, 2", "1073741824, 2", "1073741824, 4",
        "715827883, 3", "2147483448, 1", "1073741724, 2"})
    void anOffsetBeyondTheLastRowIsClampedSoThePageIsEmptyInsteadOfWrapping(int page, int size) {
        assertThat(PageOffset.of(page, size)).isEqualTo(PageOffset.BEYOND_ANY_ROW);
    }

    @Test
    void beyondAnyRowLeavesRoomForTheLargestPageSoOffsetPlusLimitFitsInAnInt() {
        assertThat(PageOffset.BEYOND_ANY_ROW).isEqualTo(Integer.MAX_VALUE - PageOffset.MAX_SIZE);
    }

    @ParameterizedTest
    @CsvSource({"-1, 50", "-2147483648, 50", "0, 0", "0, -1", "0, 201", "5, 2147483647"})
    void aPageOutsideTheContractIsRejected(int page, int size) {
        assertThatThrownBy(() -> PageOffset.of(page, size))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("page >= 0 and size 1..200 required");
    }
}
