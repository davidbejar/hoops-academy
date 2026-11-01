package com.hoopsacademy.athlete.domain;

import java.time.Instant;

/** A computed occurrence of a schedule: what the materialiser produces, before it becomes a session. */
public record PlannedSlot(ScheduleId scheduleId, TeamId teamId, Instant startsAt, Instant endsAt, String location) {}
