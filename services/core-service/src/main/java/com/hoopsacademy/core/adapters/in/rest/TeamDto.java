package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.paging.PageMeta;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.core.application.roster.TeamView;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import java.util.List;
import java.util.UUID;

/** Contract {@code Team}. */
public record TeamDto(UUID id, UUID seasonId, boolean seasonEnded, String name, String alias,
        AgeCategoryDto ageCategory, GenderPolicy genderPolicy, long playerCount) {

    /** Contract {@code TeamPage}. */
    public record PageDto(List<TeamDto> items, PageMeta page) {

        static PageDto of(PageResult<TeamView> result) {
            return new PageDto(result.items().stream().map(TeamDto::of).toList(), PageMeta.of(result));
        }
    }

    static TeamDto of(TeamView view) {
        return new TeamDto(view.team().id().value(), view.team().season().value(), view.seasonEnded(), view.team().name(),
                view.team().alias(), AgeCategoryDto.of(view.category()), view.team().genderPolicy(), view.playerCount());
    }
}
