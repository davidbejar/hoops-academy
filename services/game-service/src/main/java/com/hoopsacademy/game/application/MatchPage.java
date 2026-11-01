package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import java.util.List;

public record MatchPage(List<Match> items, int page, int size, long totalElements) {

    public MatchPage {
        items = List.copyOf(items);
    }

    public int totalPages() {
        return (int) ((totalElements + size - 1) / size);
    }
}
