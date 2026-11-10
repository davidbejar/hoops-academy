package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import com.hoopsacademy.core.application.players.PlayerView;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Contract {@code Player}. */
public record PlayerDto(UUID id, UUID personId, String givenName, String familyName, String displayName,
        LocalDate birthDate, Gender gender, PlayerStatus status, AgeCategoryDto naturalCategory,
        List<AssignmentDto> teams, Instant createdAt, String preferredJerseyNumber) {

    /** Contract {@code PlayerTeamAssignment}. */
    public record AssignmentDto(RefDtos.TeamRef team, String jerseyNumber, int playUpLevels, boolean valid) {}

    /** Contract {@code PlayerPage}. */
    public record PageDto(List<PlayerDto> items, PageMetaDto page) {

        static PageDto of(PageResult<PlayerView> result) {
            return new PageDto(result.items().stream().map(PlayerDto::of).toList(), PageMetaDto.of(result));
        }
    }

    static PlayerDto of(PlayerView view) {
        PlayerSummary p = view.row().summary();
        return new PlayerDto(p.id().value(), p.person().value(), p.givenName(), p.familyName(), p.displayName(), p.birthDate(),
                p.gender(), p.status(), AgeCategoryDto.of(view.naturalCategory()),
                view.teams().stream().map(a -> new AssignmentDto(new RefDtos.TeamRef(a.team().value(), a.teamName()),
                        a.jersey() == null ? null : a.jersey().value(), a.playUpLevels(), a.valid())).toList(),
                view.row().createdAt(), p.preferredJersey() == null ? null : p.preferredJersey().value());
    }
}
