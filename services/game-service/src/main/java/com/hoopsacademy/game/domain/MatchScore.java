package com.hoopsacademy.game.domain;

/** Read-only snapshot of the projected score of a match and the last event sequence number it includes. */
public record MatchScore(int team, int opponent, long lastServerSeq) {

    public static final MatchScore NONE = new MatchScore(0, 0, 0);
}
