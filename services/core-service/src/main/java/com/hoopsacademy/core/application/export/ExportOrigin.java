package com.hoopsacademy.core.application.export;

import java.time.LocalDate;
import java.time.ZoneId;

/**
 * Where and when an export was made (ADR-0048): the slug for the file name, the time zone of its dates and times,
 * and the day of the file name in that zone.
 */
public record ExportOrigin(String academySlug, ZoneId zone, LocalDate day) {}
