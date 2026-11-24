package com.hoopsacademy.common.paging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** One page of a list (LIB-04): the request it answers, its items and the total, as common.yaml's PageMeta. */
class PageResultTest {

    @ParameterizedTest
    @CsvSource({"-1, 50", "0, 0", "0, 201"})
    void aPageRequestOutsideTheContractIsRefused(int page, int size) {
        assertThatThrownBy(() -> new PageRequest(page, size)).isInstanceOf(IllegalArgumentException.class);
    }

    @ParameterizedTest
    @CsvSource({"0, 1, 0", "2, 200, 400", "3, 7, 21"})
    void theOffsetIsPageTimesSize(int page, int size, int offset) {
        assertThat(new PageRequest(page, size).offset()).isEqualTo(offset);
    }

    @Test
    void anOverflowingOffsetIsClampedSoThePageIsEmpty() {
        assertThat(new PageRequest(Integer.MAX_VALUE, 200).offset()).isEqualTo(PageOffset.BEYOND_ANY_ROW);
    }

    @ParameterizedTest
    @CsvSource({"0, 10, 0", "1, 10, 1", "10, 10, 1", "11, 10, 2", "200, 50, 4", "201, 50, 5"})
    void totalPagesRoundUp(long total, int size, int pages) {
        assertThat(new PageResult<>(List.of(), new PageRequest(0, size), total).totalPages()).isEqualTo(pages);
    }

    @Test
    void theItemsAreACopy() {
        List<String> items = new ArrayList<>(List.of("a"));
        PageResult<String> result = new PageResult<>(items, new PageRequest(0, 10), 1);

        items.add("b");

        assertThat(result.items()).containsExactly("a");
    }

    @Test
    void mappingKeepsTheRequestAndTheTotal() {
        PageResult<Integer> mapped = new PageResult<>(List.of("a", "bb"), new PageRequest(2, 2), 7).map(String::length);

        assertThat(mapped.items()).containsExactly(1, 2);
        assertThat(mapped.page()).isEqualTo(2);
        assertThat(mapped.size()).isEqualTo(2);
        assertThat(mapped.totalElements()).isEqualTo(7);
    }

    @Test
    void anEmptyPageAnswersTheRequestWithNothing() {
        PageResult<String> empty = PageResult.empty(new PageRequest(3, 25));

        assertThat(empty.items()).isEmpty();
        assertThat(empty.totalElements()).isZero();
        assertThat(empty.totalPages()).isZero();
        assertThat(empty.request()).isEqualTo(new PageRequest(3, 25));
    }

    @Test
    void thePageMetaIsTheContractsFigures() {
        PageMeta meta = PageMeta.of(new PageResult<>(List.of("a"), new PageRequest(1, 20), 41));

        assertThat(meta).isEqualTo(new PageMeta(1, 20, 41, 3));
    }
}
