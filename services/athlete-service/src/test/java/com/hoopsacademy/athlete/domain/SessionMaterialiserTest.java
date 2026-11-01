package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;

class SessionMaterialiserTest {

    static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");
    static final TeamId TEAM = TeamId.random();

    static TrainingSchedule weekly(DayOfWeek day, String time, int minutes, LocalDate from, LocalDate until) {
        return TrainingSchedule.create(TEAM, day, LocalTime.parse(time), minutes, "Main court", from, until);
    }

    static List<ZonedDateTime> localStarts(List<PlannedSlot> slots, ZoneId zone) {
        return slots.stream().map(s -> s.startsAt().atZone(zone)).toList();
    }

    @Test
    void producesOneSlotPerMatchingWeekdayInTheWindow() {
        var schedule = weekly(DayOfWeek.TUESDAY, "18:00", 90, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(schedule), LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 22), MADRID);

        assertThat(localStarts(slots, MADRID)).extracting(ZonedDateTime::toLocalDate)
                .containsExactly(LocalDate.of(2026, 11, 3), LocalDate.of(2026, 11, 10), LocalDate.of(2026, 11, 17));
        assertThat(slots).allSatisfy(s -> {
            assertThat(Duration.between(s.startsAt(), s.endsAt())).isEqualTo(Duration.ofMinutes(90));
            assertThat(s.location()).isEqualTo("Main court");
            assertThat(s.teamId()).isEqualTo(TEAM);
        });
    }

    @Test
    void windowBoundsAreInclusive() {
        var schedule = weekly(DayOfWeek.MONDAY, "10:00", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(schedule), LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 9), MADRID);

        assertThat(localStarts(slots, MADRID)).extracting(ZonedDateTime::toLocalDate)
                .containsExactly(LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 9));
    }

    @Test
    void emptyWhenWindowIsReversed() {
        var schedule = weekly(DayOfWeek.MONDAY, "10:00", 60, LocalDate.of(2026, 1, 1), null);

        assertThat(SessionMaterialiser.slots(List.of(schedule), LocalDate.of(2026, 11, 9), LocalDate.of(2026, 11, 2), MADRID))
                .isEmpty();
    }

    @Test
    void weekBoundaryCaseSundayAndMondayAroundTheWeekChange() {
        var sunday = weekly(DayOfWeek.SUNDAY, "23:30", 30, LocalDate.of(2026, 1, 1), null);
        var monday = weekly(DayOfWeek.MONDAY, "00:15", 30, LocalDate.of(2026, 1, 1), null);

        // Sunday 2026-11-08 .. Monday 2026-11-09: the window ends exactly on the Monday
        var slots = SessionMaterialiser.slots(List.of(sunday, monday), LocalDate.of(2026, 11, 8), LocalDate.of(2026, 11, 9), MADRID);

        assertThat(localStarts(slots, MADRID)).extracting(z -> z.toLocalDate() + " " + z.toLocalTime())
                .containsExactly("2026-11-08 23:30", "2026-11-09 00:15");
        // 23:30 Madrid on Sunday is 22:30Z, still Sunday in UTC; 00:15 Madrid on Monday is 23:15Z on Sunday in UTC
        assertThat(slots.get(1).startsAt().toString()).isEqualTo("2026-11-08T23:15:00Z");
    }

    @Test
    void validityRangeIsInclusiveAndOpenEndedWhenUntilIsNull() {
        var bounded = weekly(DayOfWeek.WEDNESDAY, "17:00", 60, LocalDate.of(2026, 11, 11), LocalDate.of(2026, 11, 18));

        var slots = SessionMaterialiser.slots(List.of(bounded), LocalDate.of(2026, 11, 1), LocalDate.of(2026, 12, 31), MADRID);

        assertThat(localStarts(slots, MADRID)).extracting(ZonedDateTime::toLocalDate)
                .containsExactly(LocalDate.of(2026, 11, 11), LocalDate.of(2026, 11, 18));
    }

    @Test
    void endedScheduleProducesNothing() {
        var ended = weekly(DayOfWeek.MONDAY, "10:00", 60, LocalDate.of(2026, 1, 1), null).ended();

        assertThat(SessionMaterialiser.slots(List.of(ended), LocalDate.of(2026, 11, 1), LocalDate.of(2026, 12, 31), MADRID))
                .isEmpty();
    }

    @Test
    void madridKeepsWallClockAcrossSpringForward() {
        // DST starts Sunday 2026-03-29 02:00 -> 03:00. Training every Saturday and Monday at 18:00 local time.
        var saturday = weekly(DayOfWeek.SATURDAY, "18:00", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(saturday), LocalDate.of(2026, 3, 21), LocalDate.of(2026, 4, 4), MADRID);

        assertThat(localStarts(slots, MADRID)).extracting(z -> z.toLocalTime().toString()).containsOnly("18:00");
        assertThat(slots).extracting(s -> s.startsAt().toString())
                .containsExactly("2026-03-21T17:00:00Z", "2026-03-28T17:00:00Z", "2026-04-04T16:00:00Z");
        // the 28 Mar -> 4 Apr week is one hour shorter in UTC (167 h), not 168 h
        assertThat(Duration.between(slots.get(1).startsAt(), slots.get(2).startsAt())).isEqualTo(Duration.ofHours(167));
    }

    @Test
    void madridKeepsWallClockAcrossFallBack() {
        // DST ends Sunday 2026-10-25 03:00 -> 02:00.
        var monday = weekly(DayOfWeek.MONDAY, "18:00", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(monday), LocalDate.of(2026, 10, 19), LocalDate.of(2026, 10, 26), MADRID);

        assertThat(slots).extracting(s -> s.startsAt().toString())
                .containsExactly("2026-10-19T16:00:00Z", "2026-10-26T17:00:00Z");
        assertThat(Duration.between(slots.get(0).startsAt(), slots.get(1).startsAt())).isEqualTo(Duration.ofHours(169));
    }

    @Test
    void sessionOnTheSpringForwardDayAtANonExistentTimeMovesIntoTheGap() {
        // 02:30 does not exist on Sunday 2026-03-29 in Madrid; it resolves to 03:30 local (01:30Z)
        var sunday = weekly(DayOfWeek.SUNDAY, "02:30", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(sunday), LocalDate.of(2026, 3, 29), LocalDate.of(2026, 3, 29), MADRID);

        assertThat(slots).hasSize(1);
        assertThat(slots.get(0).startsAt()).isEqualTo(Instant.parse("2026-03-29T01:30:00Z"));
        assertThat(slots.get(0).startsAt().atZone(MADRID).toLocalTime()).isEqualTo(LocalTime.of(3, 30));
    }

    @Test
    void sessionOnTheFallBackDayInTheRepeatedHourTakesTheEarlierOffset() {
        var sunday = weekly(DayOfWeek.SUNDAY, "02:30", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(sunday), LocalDate.of(2026, 10, 25), LocalDate.of(2026, 10, 25), MADRID);

        assertThat(slots.get(0).startsAt()).isEqualTo(Instant.parse("2026-10-25T00:30:00Z"));
    }

    @Test
    void sessionSpanningTheTransitionHasRealElapsedLength() {
        // 01:30 + 90 min on the spring-forward day ends at 04:00 local (only 30 wall-clock minutes of that is after the gap)
        var sunday = weekly(DayOfWeek.SUNDAY, "01:30", 90, LocalDate.of(2026, 1, 1), null);

        var slot = SessionMaterialiser.slots(List.of(sunday), LocalDate.of(2026, 3, 29), LocalDate.of(2026, 3, 29), MADRID).get(0);

        assertThat(slot.endsAt().atZone(MADRID).toLocalTime()).isEqualTo(LocalTime.of(4, 0));
        assertThat(Duration.between(slot.startsAt(), slot.endsAt())).isEqualTo(Duration.ofMinutes(90));
    }

    @Test
    void jakartaHasNoDstSoWeeklySpacingIsAlways168HoursAndOffsetIsPlus7() {
        var friday = weekly(DayOfWeek.FRIDAY, "16:00", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(friday), LocalDate.of(2026, 3, 1), LocalDate.of(2026, 11, 30), JAKARTA);

        assertThat(slots).hasSizeGreaterThan(30);
        assertThat(slots).allSatisfy(s -> assertThat(s.startsAt().toString()).endsWith("T09:00:00Z"));
        for (int i = 1; i < slots.size(); i++) {
            assertThat(Duration.between(slots.get(i - 1).startsAt(), slots.get(i).startsAt())).isEqualTo(Duration.ofHours(168));
        }
    }

    @Test
    void sameScheduleInDifferentZonesGivesDifferentInstants() {
        var friday = weekly(DayOfWeek.FRIDAY, "16:00", 60, LocalDate.of(2026, 1, 1), null);
        var day = LocalDate.of(2026, 7, 3);

        var madrid = SessionMaterialiser.slots(List.of(friday), day, day, MADRID).get(0);
        var jakarta = SessionMaterialiser.slots(List.of(friday), day, day, JAKARTA).get(0);

        assertThat(madrid.startsAt()).isEqualTo(Instant.parse("2026-07-03T14:00:00Z"));
        assertThat(jakarta.startsAt()).isEqualTo(Instant.parse("2026-07-03T09:00:00Z"));
    }

    @Test
    void slotsAheadCoversExactlyEightWeeks() {
        var monday = weekly(DayOfWeek.MONDAY, "18:00", 60, LocalDate.of(2026, 1, 1), null);
        var today = LocalDate.of(2026, 11, 2); // a Monday

        var slots = SessionMaterialiser.slotsAhead(List.of(monday), today, 8, MADRID);

        assertThat(slots).hasSize(8);
        assertThat(slots.get(7).startsAt().atZone(MADRID).toLocalDate()).isEqualTo(LocalDate.of(2026, 12, 21));
    }

    @Test
    void severalSchedulesAreMergedInChronologicalOrder() {
        var tue = weekly(DayOfWeek.TUESDAY, "18:00", 60, LocalDate.of(2026, 1, 1), null);
        var mon = weekly(DayOfWeek.MONDAY, "19:00", 60, LocalDate.of(2026, 1, 1), null);

        var slots = SessionMaterialiser.slots(List.of(tue, mon), LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 10), MADRID);

        assertThat(slots).extracting(PlannedSlot::startsAt).isSorted();
        assertThat(slots).hasSize(4);
    }
}
