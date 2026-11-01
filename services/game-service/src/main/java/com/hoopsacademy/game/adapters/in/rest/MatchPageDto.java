package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.MatchPage;
import java.util.List;

public record MatchPageDto(List<MatchDto> items, PageMetaDto page) {

    public record PageMetaDto(int page, int size, long totalElements, int totalPages) {}

    static MatchPageDto from(MatchPage p) {
        return new MatchPageDto(p.items().stream().map(MatchDto::from).toList(),
                new PageMetaDto(p.page(), p.size(), p.totalElements(), p.totalPages()));
    }
}
