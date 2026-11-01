package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

/** Merge feed for other devices (contract listMatchEvents); any member who may view the match may read it. */
@ApplicationScoped
public class GetMatchEvents {

    public record EventFeed(List<StoredEvent> events, long lastServerSeq, boolean hasMore) {

        public EventFeed {
            events = List.copyOf(events);
        }
    }

    private final MatchLookup lookup;
    private final MatchEventRepository events;

    GetMatchEvents(MatchLookup lookup, MatchEventRepository events) {
        this.lookup = lookup;
        this.events = events;
    }

    @Transactional
    public EventFeed handle(MatchId matchId, long after, int limit) {
        lookup.require(matchId);
        List<StoredEvent> page = events.after(matchId, after, limit + 1);
        boolean hasMore = page.size() > limit;
        return new EventFeed(hasMore ? page.subList(0, limit) : page, events.lastServerSeq(matchId), hasMore);
    }
}
