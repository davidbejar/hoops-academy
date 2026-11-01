package com.hoopsacademy.game.domain.projection;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Points per period for both sides. */
final class Scoreboard {

    private final Map<Integer, int[]> byPeriod = new TreeMap<>();

    void team(int period, int points) {
        byPeriod.computeIfAbsent(period, p -> new int[2])[0] += points;
    }

    void opponent(int period, int points) {
        byPeriod.computeIfAbsent(period, p -> new int[2])[1] += points;
    }

    /** One entry per period from 1 to {@code lastPeriod}, zeros where nobody scored. */
    MatchSummary summary(int lastPeriod, long lastServerSeq) {
        List<PeriodScore> periods = new ArrayList<>();
        int team = 0;
        int opponent = 0;
        for (int period = 1; period <= lastPeriod; period++) {
            int[] points = byPeriod.getOrDefault(period, new int[2]);
            periods.add(new PeriodScore(period, points[0], points[1]));
            team += points[0];
            opponent += points[1];
        }
        return new MatchSummary(team, opponent, periods, lastServerSeq);
    }
}
