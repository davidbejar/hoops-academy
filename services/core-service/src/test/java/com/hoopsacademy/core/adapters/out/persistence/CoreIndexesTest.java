package com.hoopsacademy.core.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/** The access paths the migrations leave (audit 2026-11-23): an index for a measured read, none without a reader. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreIndexesTest {

    @Test
    void theUsageSnapshotsAreReadThroughTheDayIndexOnly() {
        // CORE-12: every read and the upsert go through usage_snapshot_day_uq (tenant_id, snapshot_date) since V7
        assertThat(indexes("usage_snapshot_tenant_idx")).isZero();
        assertThat(indexes("usage_snapshot_day_uq")).isOne();
    }

    @Test
    void theOpenCasesOfAPlayerHaveAnIndex() {
        // CORE-20: EligibilityCaseRepository.openOfPlayer filters c.playerId and c.status = 'OPEN'
        assertThat(CoreDb.countAsPlatform("""
                select count(*) from pg_indexes where schemaname = 'core' and indexname = 'eligibility_case_player_idx'
                   and indexdef like '%(tenant_id, player_id) WHERE (status = ''OPEN''::text)'""")).isOne();
    }

    private static long indexes(String name) {
        return CoreDb.countAsPlatform("select count(*) from pg_indexes where schemaname = 'core' and indexname = ?",
                name);
    }
}
