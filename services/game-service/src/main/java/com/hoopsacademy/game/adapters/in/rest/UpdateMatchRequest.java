package com.hoopsacademy.game.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.hoopsacademy.game.domain.HomeAway;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.time.Instant;

/** PATCH body; {@code venue} distinguishes "absent" (keep) from an explicit null (clear). */
public class UpdateMatchRequest {

    @Size(min = 1, max = 120)
    public String opponentName;

    public HomeAway homeAway;
    public Instant scheduledAt;

    @Size(max = 200)
    public String venue;

    @Min(1) @Max(8)
    public Integer periodCount;

    @Min(1) @Max(60)
    public Integer periodMinutes;

    boolean venueGiven;

    @JsonSetter("venue")
    public void setVenue(String venue) {
        this.venue = venue;
        this.venueGiven = true;
    }

    boolean isEmpty() {
        return opponentName == null && homeAway == null && scheduledAt == null && !venueGiven && periodCount == null
                && periodMinutes == null;
    }
}
