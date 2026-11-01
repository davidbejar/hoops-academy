package com.hoopsacademy.game.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.application.GetMatchEvents;
import com.hoopsacademy.game.application.IngestEventBatch;
import com.hoopsacademy.game.application.StoredEvent;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Contract DTOs of the MatchEvents tag: MatchEventBatchResult and MatchEventFeed. */
final class MatchEventDtos {

    private MatchEventDtos() {}

    /**
     * {@code reason}/{@code message} are omitted unless REJECTED (both optional in the contract): an explicit null on
     * the allOf-wrapped nullable enum cannot be validated once combinators are resolved (libs/contracts README).
     */
    record EventResultDto(UUID eventId, IngestEventBatch.Status status, Long serverSeq,
            @JsonInclude(JsonInclude.Include.NON_NULL) IngestEventBatch.RejectionReason reason,
            @JsonInclude(JsonInclude.Include.NON_NULL) String message) {}

    record BatchResultDto(List<EventResultDto> results, long lastServerSeq) {

        static BatchResultDto from(IngestEventBatch.BatchResult result) {
            return new BatchResultDto(result.results().stream()
                    .map(r -> new EventResultDto(r.eventId(), r.status(), r.serverSeq(), r.reason(), r.message()))
                    .toList(), result.lastServerSeq());
        }
    }

    record PersonRefDto(UUID personId, String displayName) {}

    record StoredMatchEventDto(long serverSeq, ObjectNode event, PersonRefDto recordedBy, Instant receivedAt,
            UUID voidedByEventId) {

        static StoredMatchEventDto from(ObjectMapper json, StoredEvent stored) {
            return new StoredMatchEventDto(stored.recorded().serverSeq(),
                    MatchEventJson.encode(json, stored.recorded().event()),
                    new PersonRefDto(stored.recordedBy().personId(), stored.recordedBy().displayName()),
                    stored.receivedAt(), stored.voidedBy() == null ? null : stored.voidedBy().value());
        }
    }

    record MatchEventFeedDto(List<StoredMatchEventDto> events, long lastServerSeq, boolean hasMore) {

        static MatchEventFeedDto from(ObjectMapper json, GetMatchEvents.EventFeed feed) {
            return new MatchEventFeedDto(feed.events().stream().map(e -> StoredMatchEventDto.from(json, e)).toList(),
                    feed.lastServerSeq(), feed.hasMore());
        }
    }
}
