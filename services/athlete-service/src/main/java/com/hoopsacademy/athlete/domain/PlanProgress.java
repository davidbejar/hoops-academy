package com.hoopsacademy.athlete.domain;

import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Who of the targeted players did what for one assignment. Completions of non-targets are ignored. */
public record PlanProgress(AssignmentId assignmentId, List<PlayerProgress> players) {

    public record PlayerProgress(PlayerId playerId, Optional<PlanCompletion> completion) {}

    public static PlanProgress of(AssignmentId assignment, Collection<PlayerId> targets, Collection<PlanCompletion> completions) {
        Map<PlayerId, PlanCompletion> byPlayer = completions.stream()
                .collect(Collectors.toMap(PlanCompletion::playerId, Function.identity(), (a, b) -> b));
        return new PlanProgress(assignment, targets.stream()
                .map(p -> new PlayerProgress(p, Optional.ofNullable(byPlayer.get(p)))).toList());
    }

    public int total() {
        return players.size();
    }

    public int count(CompletionStatus status) {
        return (int) players.stream().filter(p -> p.completion().filter(c -> c.status() == status).isPresent()).count();
    }

    public int notRecorded() {
        return (int) players.stream().filter(p -> p.completion().isEmpty()).count();
    }

    public Map<CompletionStatus, Integer> counts() {
        Map<CompletionStatus, Integer> counts = new EnumMap<>(CompletionStatus.class);
        for (CompletionStatus status : CompletionStatus.values()) {
            counts.put(status, count(status));
        }
        return counts;
    }
}
