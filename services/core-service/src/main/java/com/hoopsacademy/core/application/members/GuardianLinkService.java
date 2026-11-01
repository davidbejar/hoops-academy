package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.GuardianLink;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Guardian (PARENT) ↔ player links of the bound tenant. */
@ApplicationScoped
public class GuardianLinkService {

    public static final String GUARDIAN_NOT_PARENT = "GUARDIAN_NOT_PARENT";

    /** A link with the display names of both sides. */
    public record LinkView(GuardianLink link, String guardianName, String playerName) {}

    private final TenantContext tenantContext;
    private final GuardianLinkRepository links;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final AuthzCache authzCache;
    private final AuditLog audit;
    private final Clock clock;

    public GuardianLinkService(TenantContext tenantContext, GuardianLinkRepository links, PersonRepository persons,
            PlayerRepository players, AuthzCache authzCache, AuditLog audit, Clock clock) {
        this.tenantContext = tenantContext;
        this.links = links;
        this.persons = persons;
        this.players = players;
        this.authzCache = authzCache;
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional
    public LinkView create(PersonId guardianId, PlayerId playerId) {
        Person guardian = persons.find(guardianId).orElseThrow(() -> new NotFoundException("Guardian not found"));
        PersonId playerPerson = players.personOf(playerId).orElseThrow(() -> new NotFoundException("Player not found"));
        if (!guardian.roles().contains(TenantRole.PARENT)) {
            throw new DomainRuleViolation("The guardian must hold the PARENT role", GUARDIAN_NOT_PARENT);
        }
        if (links.exists(guardianId, playerId)) {
            throw new ConflictException("The guardian is already linked to this player", "GUARDIAN_LINK_EXISTS");
        }
        GuardianLink link = new GuardianLink(GuardianLinkId.random(), guardianId, playerId, clock.instant());
        links.insert(link);
        authzCache.invalidate(tenantContext.requireTenantId());
        audit.record(AuditEvent.of("guardian_link.created", "guardian_link", link.id().value(), Map.of(
                "guardianPersonId", guardianId.value().toString(), "playerId", playerId.value().toString())));
        return withNames(List.of(link), Map.of(playerId, playerPerson)).get(0);
    }

    @Transactional
    public void delete(GuardianLinkId id) {
        links.find(id).orElseThrow(() -> new NotFoundException("Guardian link not found"));
        links.delete(id);
        authzCache.invalidate(tenantContext.requireTenantId());
        audit.record(AuditEvent.of("guardian_link.removed", "guardian_link", id.value()));
    }

    @Transactional
    public PageResult<LinkView> list(Optional<PlayerId> player, Optional<PersonId> guardian, PageRequest page) {
        PageResult<GuardianLink> result = links.list(player, guardian, page);
        Map<PlayerId, PersonId> playerPersons = new java.util.HashMap<>();
        result.items().forEach(link -> players.personOf(link.player())
                .ifPresent(person -> playerPersons.put(link.player(), person)));
        List<LinkView> views = withNames(result.items(), playerPersons);
        return new PageResult<>(views, page, result.totalElements());
    }

    private List<LinkView> withNames(List<GuardianLink> found, Map<PlayerId, PersonId> playerPersons) {
        Set<PersonId> ids = new HashSet<>(playerPersons.values());
        found.forEach(link -> ids.add(link.guardian()));
        Map<PersonId, String> names = persons.findAll(ids).stream()
                .collect(Collectors.toMap(Person::id, Person::displayName, (a, b) -> a));
        Function<PersonId, String> name = id -> names.getOrDefault(id, "");
        return found.stream().map(link -> new LinkView(link, name.apply(link.guardian()),
                name.apply(playerPersons.get(link.player())))).toList();
    }
}
