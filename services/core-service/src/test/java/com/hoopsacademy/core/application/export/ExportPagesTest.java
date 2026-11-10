package com.hoopsacademy.core.application.export;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** ADR-0048: an export reads the paged trail to its end, once per row, and refuses more than 10,000 rows early. */
class ExportPagesTest {

    @Test
    void everyPageIsReadUntilAShortOne() {
        List<Integer> rows = IntStream.range(0, 450).boxed().toList();
        List<PageRequest> asked = new ArrayList<>();

        List<Integer> all = ExportPages.readAll(page -> {
            asked.add(page);
            return slice(rows, page);
        }, Function.identity());

        assertThat(all).isEqualTo(rows);
        assertThat(asked).extracting(PageRequest::page).containsExactly(0, 1, 2);
        assertThat(asked).extracting(PageRequest::size).containsOnly(ExportPages.PAGE_SIZE);
        assertThat(ExportPages.PAGE_SIZE).isEqualTo(200);
    }

    @Test
    void aFullLastPageIsFollowedByOneEmptyRead() {
        List<Integer> rows = IntStream.range(0, 400).boxed().toList();
        List<PageRequest> asked = new ArrayList<>();

        assertThat(ExportPages.readAll(page -> {
            asked.add(page);
            return slice(rows, page);
        }, Function.identity())).hasSize(400);
        assertThat(asked).hasSize(3);
        assertThat(ExportPages.readAll(page -> slice(List.<Integer>of(), page), Function.identity())).isEmpty();
    }

    @Test
    void aRowPushedOntoTheNextPageByANewerOneIsKeptOnce() {
        List<Integer> before = IntStream.range(0, 250).boxed().toList();
        List<Integer> after = new ArrayList<>(List.of(-1));
        after.addAll(before);

        List<Integer> all = ExportPages.readAll(page -> slice(page.page() == 0 ? before : after, page),
                Function.identity());

        assertThat(all).isEqualTo(before);
    }

    @Test
    void moreThanTenThousandRowsAreRefusedBeforeTheSecondPage() {
        List<PageRequest> asked = new ArrayList<>();

        assertThatThrownBy(() -> ExportPages.readAll(page -> {
            asked.add(page);
            return new PageResult<>(IntStream.range(0, 200).boxed().toList(), page, 10_001);
        }, Function.identity())).isInstanceOf(DomainRuleViolation.class).extracting("code")
                .isEqualTo("EXPORT_TOO_LARGE");
        assertThat(asked).hasSize(1);
    }

    @Test
    void rowsAddedWhileReadingStillCountAgainstTheLimit() {
        assertThatThrownBy(() -> ExportPages.readAll(page -> new PageResult<>(IntStream
                .range(page.page() * 200, page.page() * 200 + 200).boxed().toList(), page, 10_000),
                Function.identity())).isInstanceOf(DomainRuleViolation.class);
    }

    private static PageResult<Integer> slice(List<Integer> rows, PageRequest page) {
        int from = Math.min(page.offset(), rows.size());
        int to = Math.min(from + page.size(), rows.size());
        return new PageResult<>(rows.subList(from, to), page, rows.size());
    }
}
