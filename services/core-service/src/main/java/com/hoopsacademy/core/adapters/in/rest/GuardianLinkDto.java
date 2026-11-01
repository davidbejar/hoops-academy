package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.members.GuardianLinkService.LinkView;
import java.time.Instant;
import java.util.UUID;

/** Contract {@code GuardianLink} (guardian is a {@code PersonRef}, player a {@code PlayerRef}). */
public record GuardianLinkDto(UUID id, PersonRefDto guardian, PlayerRefDto player, Instant createdAt) {

    public record PersonRefDto(UUID personId, String displayName) {}

    public record PlayerRefDto(UUID id, String displayName) {}

    static GuardianLinkDto of(LinkView view) {
        return new GuardianLinkDto(view.link().id().value(),
                new PersonRefDto(view.link().guardian().value(), view.guardianName()),
                new PlayerRefDto(view.link().player().value(), view.playerName()), view.link().createdAt());
    }
}
