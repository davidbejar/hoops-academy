package com.hoopsacademy.game.domain.projection;

/** Points of both sides in one period (overtimes included). */
public record PeriodScore(int period, int team, int opponent) {}
