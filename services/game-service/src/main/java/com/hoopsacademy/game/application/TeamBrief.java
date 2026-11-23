package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;

/**
 * A team without its roster: name, season and the season's last day ({@code null} when core did not say; counts as not
 * ended, ADR-0042).
 */
public record TeamBrief(TeamId teamId, SeasonId seasonId, String teamName, LocalDate seasonEndDate) {}
