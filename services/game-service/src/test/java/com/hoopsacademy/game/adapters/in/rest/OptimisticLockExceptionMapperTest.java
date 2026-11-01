package com.hoopsacademy.game.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.problem.Problem;
import jakarta.persistence.OptimisticLockException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.hibernate.StaleObjectStateException;
import org.junit.jupiter.api.Test;

class OptimisticLockExceptionMapperTest {

    final OptimisticLockExceptionMapper mapper = new OptimisticLockExceptionMapper();
    final UriInfo uri = mock(UriInfo.class);

    @Test
    void versionConflictsAre409ProblemsWithACode() {
        when(uri.getPath()).thenReturn("api/game/matches/1");

        for (Response response : new Response[] {
                mapper.optimisticLock(new OptimisticLockException("stale"), uri),
                mapper.staleState(new StaleObjectStateException("MatchEntity", 1), uri)}) {
            assertThat(response.getStatus()).isEqualTo(409);
            assertThat(response.getMediaType().toString()).isEqualTo(Problem.MEDIA_TYPE);
            Problem problem = (Problem) response.getEntity();
            assertThat(problem.code()).isEqualTo("CONCURRENT_MODIFICATION");
            assertThat(problem.instance()).isEqualTo("/api/game/matches/1");
            assertThat(problem.detail()).doesNotContain("MatchEntity");
        }
    }
}
