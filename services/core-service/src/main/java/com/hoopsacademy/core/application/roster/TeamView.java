package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.Team;

/** A team with its category and the number of open, valid assignments. */
public record TeamView(Team team, AgeCategory category, long playerCount) {}
