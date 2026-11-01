package com.hoopsacademy.athlete.domain;

import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Pure calculation of the occurrences of recurring schedules in a date window. The wall-clock start time is
 * resolved in the tenant's time zone for each date, so a 18:00 training stays at 18:00 local time across daylight
 * saving transitions (the UTC instant moves). A wall-clock time that does not exist on a spring-forward day is
 * shifted forward by the gap, as {@link ZonedDateTime#of} does; an ambiguous time on a fall-back day takes the
 * earlier offset. The slot length is real elapsed time.
 */
public final class SessionMaterialiser {

    private SessionMaterialiser() {}

    /** @param from first date (inclusive); @param to last date (inclusive) */
    public static List<PlannedSlot> slots(List<TrainingSchedule> schedules, LocalDate from, LocalDate to, ZoneId zone) {
        if (to.isBefore(from)) {
            return List.of();
        }
        return from.datesUntil(to.plusDays(1))
                .flatMap(date -> schedules.stream().filter(s -> s.occursOn(date)).map(s -> slot(s, date, zone)))
                .sorted(Comparator.comparing(PlannedSlot::startsAt).thenComparing(s -> s.scheduleId().toString()))
                .toList();
    }

    /** Convenience: the window starting today (in the tenant zone) and ending {@code horizonWeeks} weeks later. */
    public static List<PlannedSlot> slotsAhead(List<TrainingSchedule> schedules, LocalDate today, int horizonWeeks,
            ZoneId zone) {
        return slots(schedules, today, today.plusWeeks(horizonWeeks).minusDays(1), zone);
    }

    private static PlannedSlot slot(TrainingSchedule schedule, LocalDate date, ZoneId zone) {
        ZonedDateTime start = ZonedDateTime.of(date, schedule.startTime(), zone);
        return new PlannedSlot(schedule.id(), schedule.teamId(), start.toInstant(),
                start.toInstant().plus(Duration.ofMinutes(schedule.durationMinutes())), schedule.location());
    }
}
