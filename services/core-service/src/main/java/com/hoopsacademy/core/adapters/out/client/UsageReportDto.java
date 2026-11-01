package com.hoopsacademy.core.adapters.out.client;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Wire form of the shared {@code UsageReport} schema. */
public record UsageReportDto(UUID tenantId, String service, Instant collectedAt, Instant lastActivityAt,
        Map<String, Long> counters) {}
