package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class DomainModelTest {

    static final TeamId TEAM = TeamId.random();
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");
    static final Instant T0 = Instant.parse("2026-11-03T17:00:00Z");

    // ---- schedule
    @Test
    void scheduleRejectsOutOfRangeDurationAndInvertedValidity() {
        assertThatThrownBy(() -> TrainingSchedule.create(TEAM, DayOfWeek.MONDAY, LocalTime.NOON, 14, null, LocalDate.of(2026, 1, 1), null))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("INVALID_DURATION");
        assertThatThrownBy(() -> TrainingSchedule.create(TEAM, DayOfWeek.MONDAY, LocalTime.NOON, 481, null, LocalDate.of(2026, 1, 1), null))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> TrainingSchedule.create(TEAM, DayOfWeek.MONDAY, LocalTime.NOON, 60, null,
                LocalDate.of(2026, 2, 1), LocalDate.of(2026, 1, 31)))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("INVALID_VALIDITY_RANGE");
    }

    @Test
    void scheduleDropsSecondsAndTracksValidity() {
        var s = TrainingSchedule.create(TEAM, DayOfWeek.MONDAY, LocalTime.of(18, 0, 30), 60, null,
                LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 31));

        assertThat(s.startTime()).isEqualTo(LocalTime.of(18, 0));
        assertThat(s.isValidOn(LocalDate.of(2026, 1, 31))).isTrue();
        assertThat(s.isValidOn(LocalDate.of(2026, 2, 1))).isFalse();
        assertThat(s.isValidOn(LocalDate.of(2025, 12, 31))).isFalse();
        assertThat(s.occursOn(LocalDate.of(2026, 1, 5))).isTrue();   // a Monday
        assertThat(s.occursOn(LocalDate.of(2026, 1, 6))).isFalse();
        assertThat(s.ended().isValidOn(LocalDate.of(2026, 1, 5))).isFalse();
        assertThat(s.changedTo(DayOfWeek.FRIDAY, LocalTime.NOON, 45, "Gym", s.validFrom(), null).id()).isEqualTo(s.id());
    }

    // ---- session
    @Test
    void adHocSessionIsPlannedWithComputedEnd() {
        var session = TrainingSession.adHoc(TEAM, T0, 90, "Gym", null, "notes");

        assertThat(session.status()).isEqualTo(SessionStatus.PLANNED);
        assertThat(session.endsAt()).isEqualTo(T0.plusSeconds(5400));
        assertThat(session.durationMinutes()).isEqualTo(90);
        assertThat(session.schedule()).isEmpty();
        assertThat(session.manuallyEdited()).isFalse();
    }

    @Test
    void sessionMustEndAfterItStarts() {
        assertThatThrownBy(() -> new TrainingSession(SessionId.random(), TEAM, null, T0, T0, null, null,
                SessionStatus.PLANNED, null, null, false)).isInstanceOf(TrainingRuleViolation.class);
    }

    @Test
    void cancellingKeepsDataAndFreezesTheSession() {
        var session = TrainingSession.adHoc(TEAM, T0, 60, null, null, null);

        var cancelled = session.cancelled("Hall closed");

        assertThat(cancelled.isCancelled()).isTrue();
        assertThat(cancelled.cancelReason()).isEqualTo("Hall closed");
        assertThatThrownBy(() -> cancelled.cancelled("again")).isInstanceOf(TrainingStateConflict.class);
        assertThatThrownBy(() -> cancelled.edited(T0, 60, null, null, null, SessionStatus.PLANNED))
                .isInstanceOf(TrainingStateConflict.class);
    }

    @Test
    void doneSessionCannotBeCancelled() {
        var done = TrainingSession.adHoc(TEAM, T0, 60, null, null, null).edited(T0, 60, null, null, null, SessionStatus.DONE);

        assertThatThrownBy(() -> done.cancelled("late")).isInstanceOf(TrainingStateConflict.class);
    }

    @Test
    void editingMarksManualAndRefusesCancelledStatus() {
        var session = TrainingSession.adHoc(TEAM, T0, 60, null, null, null);
        var plan = UUID.randomUUID();

        var edited = session.edited(T0.plusSeconds(3600), 75, "Court 2", plan, "bring bibs", SessionStatus.DONE);

        assertThat(edited.manuallyEdited()).isTrue();
        assertThat(edited.startsAt()).isEqualTo(T0.plusSeconds(3600));
        assertThat(edited.endsAt()).isEqualTo(T0.plusSeconds(3600 + 4500));
        assertThat(edited.planId()).isEqualTo(plan);
        assertThatThrownBy(() -> session.edited(T0, 60, null, null, null, SessionStatus.CANCELLED))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("USE_CANCEL");
    }

    @Test
    void materialisedSessionComesFromTheSlot() {
        var schedule = TrainingSchedule.create(TEAM, DayOfWeek.TUESDAY, LocalTime.of(18, 0), 60, "Main", LocalDate.of(2026, 1, 1), null);
        var slot = new PlannedSlot(schedule.id(), TEAM, T0, T0.plusSeconds(3600), "Main");

        var session = TrainingSession.materialised(slot);

        assertThat(session.schedule()).contains(schedule.id());
        assertThat(session.status()).isEqualTo(SessionStatus.PLANNED);
        assertThat(session.manuallyEdited()).isFalse();
    }

    // ---- attendance
    @Test
    void lateRequiresMinutesAndOthersForbidThem() {
        var session = SessionId.random();
        var player = PlayerId.random();

        assertThat(new Attendance(session, player, AttendanceStatus.LATE, 10, null, COACH, T0).minutesLate()).isEqualTo(10);
        assertThat(new Attendance(session, player, AttendanceStatus.PRESENT, null, "ok", COACH, T0).minutesLate()).isNull();
        assertThatThrownBy(() -> new Attendance(session, player, AttendanceStatus.LATE, null, null, COACH, T0))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("MINUTES_LATE_REQUIRED");
        assertThatThrownBy(() -> new Attendance(session, player, AttendanceStatus.LATE, 0, null, COACH, T0))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> new Attendance(session, player, AttendanceStatus.LATE, 481, null, COACH, T0))
                .isInstanceOf(TrainingRuleViolation.class);
        assertThatThrownBy(() -> new Attendance(session, player, AttendanceStatus.ABSENT, 5, null, COACH, T0))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("MINUTES_LATE_NOT_ALLOWED");
    }

    // ---- planned absence
    @Test
    void absenceRangeIsInclusiveAndValidated() {
        var player = PlayerId.random();
        var absence = PlannedAbsence.announce(player, LocalDate.of(2026, 11, 3), LocalDate.of(2026, 11, 5), "flu", COACH, T0);

        assertThat(absence.covers(LocalDate.of(2026, 11, 3))).isTrue();
        assertThat(absence.covers(LocalDate.of(2026, 11, 5))).isTrue();
        assertThat(absence.covers(LocalDate.of(2026, 11, 6))).isFalse();
        assertThat(absence.overlaps(LocalDate.of(2026, 11, 5), LocalDate.of(2026, 11, 9))).isTrue();
        assertThat(absence.overlaps(LocalDate.of(2026, 11, 6), LocalDate.of(2026, 11, 9))).isFalse();
        assertThat(absence.changedTo(absence.fromDate(), absence.fromDate(), null).toDate()).isEqualTo(absence.fromDate());
        assertThatThrownBy(() -> PlannedAbsence.announce(player, LocalDate.of(2026, 11, 5), LocalDate.of(2026, 11, 4), null, COACH, T0))
                .isInstanceOf(TrainingRuleViolation.class).extracting("code").isEqualTo("INVALID_DATE_RANGE");
    }

    // ---- sheet overlay
    @Test
    void sheetOverlaysPlannedAbsencesAndRecordedAttendance() {
        var present = PlayerId.random();
        var away = PlayerId.random();
        var plain = PlayerId.random();
        var left = PlayerId.random(); // recorded but no longer on the roster
        var day = LocalDate.of(2026, 11, 3);
        var recorded = List.of(
                new Attendance(SessionId.random(), present, AttendanceStatus.PRESENT, null, null, COACH, T0),
                new Attendance(SessionId.random(), left, AttendanceStatus.EXCUSED, null, null, COACH, T0));
        var absences = List.of(
                PlannedAbsence.announce(away, day, day, null, COACH, T0),
                PlannedAbsence.announce(plain, day.plusDays(1), day.plusDays(2), null, COACH, T0));

        var sheet = AttendanceSheet.build(List.of(present, away, plain), recorded, absences, day);

        assertThat(sheet).hasSize(4);
        assertThat(sheet).filteredOn(e -> e.playerId().equals(away)).singleElement()
                .satisfies(e -> {
                    assertThat(e.expectedAbsent()).isTrue();
                    assertThat(e.recorded()).isEmpty();
                });
        assertThat(sheet).filteredOn(e -> e.playerId().equals(plain)).singleElement()
                .satisfies(e -> assertThat(e.expectedAbsent()).isFalse());
        assertThat(sheet).filteredOn(e -> e.playerId().equals(present)).singleElement()
                .satisfies(e -> assertThat(e.recorded().map(Attendance::status)).isEqualTo(Optional.of(AttendanceStatus.PRESENT)));
        assertThat(sheet).filteredOn(e -> e.playerId().equals(left)).hasSize(1);
    }

    @Test
    void sheetKeepsTheEarliestOfOverlappingAbsences() {
        var player = PlayerId.random();
        var day = LocalDate.of(2026, 11, 3);
        var first = PlannedAbsence.announce(player, day, day, null, COACH, T0);
        var second = PlannedAbsence.announce(player, day, day, null, COACH, T0.plusSeconds(5));

        var sheet = AttendanceSheet.build(List.of(player), List.of(), List.of(second, first), day);

        assertThat(sheet.get(0).plannedAbsence()).contains(first);
    }

    @Test
    void valueObjectsRejectNull() {
        assertThatThrownBy(() -> new TeamId(null)).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> new Actor(PersonId.random(), " ")).isInstanceOf(IllegalArgumentException.class);
        assertThat(TeamId.random().toString()).hasSize(36);
    }
}
