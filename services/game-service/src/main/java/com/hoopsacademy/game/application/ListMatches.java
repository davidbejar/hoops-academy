package com.hoopsacademy.game.application;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class ListMatches {

    private final MatchRepository matches;

    public ListMatches(MatchRepository matches) {
        this.matches = matches;
    }

    @Transactional
    public MatchPage handle(MatchFilter filter, int page, int size) {
        return matches.list(filter, page, size);
    }
}
