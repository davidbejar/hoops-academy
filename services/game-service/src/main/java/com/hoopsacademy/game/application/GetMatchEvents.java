package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.PlayerVisibility;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

/**
 * Merge feed for other devices (contract listMatchEvents); any member who may view the match may read it, filtered by
 * {@link StatVisibility} and {@link com.hoopsacademy.game.domain.events.EventVisibility} (ADR-0030): ADMIN and staff of the team read every event,
 * anybody else the team-level events plus those of their own or linked players. Paging walks the visible events only,
 * filtered in the query (WP60), so a page costs the same few statements whatever the size of the match;
 * {@code lastServerSeq} is the match's highest sequence number for every caller.
 */
@ApplicationScoped
public class GetMatchEvents {

    public record EventFeed(List<StoredEvent> events, long lastServerSeq, boolean hasMore) {

        public EventFeed {
            events = List.copyOf(events);
        }
    }

    private final MatchLookup lookup;
    private final MatchEventRepository events;
    private final CurrentCaller caller;

    GetMatchEvents(MatchLookup lookup, MatchEventRepository events, CurrentCaller caller) {
        this.lookup = lookup;
        this.events = events;
        this.caller = caller;
    }

    @Transactional
    public EventFeed handle(MatchId matchId, long after, int limit) {
        Match match = lookup.require(matchId);
        PlayerVisibility viewer = StatVisibility.forTeam(caller.authz(), match.teamId());
        List<StoredEvent> page = events.after(matchId, viewer, after, limit + 1);
        boolean hasMore = page.size() > limit;
        return new EventFeed(hasMore ? page.subList(0, limit) : page, events.lastServerSeq(matchId), hasMore);
    }
}
