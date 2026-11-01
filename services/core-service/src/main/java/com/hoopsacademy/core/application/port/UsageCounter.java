package com.hoopsacademy.core.application.port;

import java.util.Map;

/**
 * Contributes core usage counters of the bound tenant (members, players, … — WP4 adds teams/seasons by
 * providing another implementation). Called inside a tenant-bound transaction.
 */
public interface UsageCounter {

    Map<String, Long> counters();
}
