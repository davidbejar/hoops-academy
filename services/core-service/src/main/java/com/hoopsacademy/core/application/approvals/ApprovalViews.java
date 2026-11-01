package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/** Resolves the names of requests with two queries for any number of them. */
@ApplicationScoped
public class ApprovalViews {

    private final PlayerRepository players;
    private final PersonRepository persons;

    public ApprovalViews(PlayerRepository players, PersonRepository persons) {
        this.players = players;
        this.persons = persons;
    }

    public List<ApprovalView> of(List<ApprovalRequest> requests) {
        if (requests.isEmpty()) {
            return List.of();
        }
        Map<PlayerId, PlayerSummary> playersById = players.summaries(
                requests.stream().map(ApprovalRequest::player).distinct().toList());
        Map<PersonId, String> names = persons.findAll(requests.stream()
                        .flatMap(r -> Stream.of(r.requestedBy(), r.decidedBy())).filter(Objects::nonNull).distinct().toList())
                .stream().collect(Collectors.toMap(Person::id, Person::displayName));
        return requests.stream().map(r -> new ApprovalView(r, playersById.get(r.player()).displayName(),
                names.get(r.requestedBy()), r.decidedBy() == null ? null : names.get(r.decidedBy()))).toList();
    }

    public ApprovalView of(ApprovalRequest request) {
        return of(List.of(request)).get(0);
    }
}
