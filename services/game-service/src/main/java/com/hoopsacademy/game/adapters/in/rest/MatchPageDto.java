package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.common.paging.PageMeta;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.game.domain.Match;
import java.util.List;

public record MatchPageDto(List<MatchDto> items, PageMeta page) {

    static MatchPageDto from(PageResult<Match> p) {
        return new MatchPageDto(p.items().stream().map(MatchDto::from).toList(), PageMeta.of(p));
    }
}
