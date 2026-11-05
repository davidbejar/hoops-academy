package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PersonRepository.MemberFilter;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.identity.TemporaryPasswordStatus;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/** Member reads of the bound tenant. */
@ApplicationScoped
public class MemberQueries {

    private final PersonRepository persons;
    private final PlayerRepository players;
    private final TemporaryPasswordLogins temporaryPasswords;

    public MemberQueries(PersonRepository persons, PlayerRepository players, TemporaryPasswordLogins temporaryPasswords) {
        this.persons = persons;
        this.players = players;
        this.temporaryPasswords = temporaryPasswords;
    }

    @Transactional
    public PageResult<MemberView> list(MemberFilter filter, PageRequest page) {
        PageResult<Person> result = persons.list(filter, page);
        Map<PersonId, PlayerId> playerIds = players.findByPersons(result.items().stream().map(Person::id).toList());
        Map<UserId, TemporaryPasswordStatus> statuses = statusesOf(result.items());
        return result.map(person -> new MemberView(person, playerOf(person, playerIds),
                statusOf(person, statuses)));
    }

    @Transactional
    public MemberView get(PersonId id) {
        return view(load(id));
    }

    @Transactional
    public MemberView view(Person person) {
        return new MemberView(person, person.isPlayer() ? players.findByPerson(person.id()) : Optional.empty(),
                statusOf(person, statusesOf(List.of(person))));
    }

    Person load(PersonId id) {
        return persons.find(id).orElseThrow(() -> new NotFoundException("Member not found"));
    }

    private Map<UserId, TemporaryPasswordStatus> statusesOf(List<Person> people) {
        return temporaryPasswords.statusOf(people.stream().map(Person::userId).filter(Objects::nonNull).toList());
    }

    private static TemporaryPasswordStatus statusOf(Person person, Map<UserId, TemporaryPasswordStatus> statuses) {
        return person.userId() == null ? TemporaryPasswordStatus.NONE
                : statuses.getOrDefault(person.userId(), TemporaryPasswordStatus.NONE);
    }

    private static Optional<PlayerId> playerOf(Person person, Map<PersonId, PlayerId> playerIds) {
        return person.isPlayer() ? Optional.ofNullable(playerIds.get(person.id())) : Optional.empty();
    }
}
