package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.Team;

/**
 * A team with its category, the number of open, valid assignments and whether its season has ended (read-only
 * history, ADR-0042).
 */
public record TeamView(Team team, AgeCategory category, long playerCount, boolean seasonEnded) {}
