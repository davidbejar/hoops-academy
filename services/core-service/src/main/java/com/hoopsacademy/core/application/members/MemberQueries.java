package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PersonRepository.MemberFilter;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Map;
import java.util.Optional;

/** Member reads of the bound tenant. */
@ApplicationScoped
public class MemberQueries {

    private final PersonRepository persons;
    private final PlayerRepository players;

    public MemberQueries(PersonRepository persons, PlayerRepository players) {
        this.persons = persons;
        this.players = players;
    }

    @Transactional
    public PageResult<MemberView> list(MemberFilter filter, PageRequest page) {
        PageResult<Person> result = persons.list(filter, page);
        Map<PersonId, PlayerId> playerIds = players.findByPersons(result.items().stream().map(Person::id).toList());
        return result.map(person -> new MemberView(person, playerOf(person, playerIds)));
    }

    @Transactional
    public MemberView get(PersonId id) {
        return view(load(id));
    }

    @Transactional
    public MemberView view(Person person) {
        return new MemberView(person, person.isPlayer() ? players.findByPerson(person.id()) : Optional.empty());
    }

    Person load(PersonId id) {
        return persons.find(id).orElseThrow(() -> new NotFoundException("Member not found"));
    }

    private static Optional<PlayerId> playerOf(Person person, Map<PersonId, PlayerId> playerIds) {
        return person.isPlayer() ? Optional.ofNullable(playerIds.get(person.id())) : Optional.empty();
    }
}
