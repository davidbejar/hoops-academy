package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.EligibilityCaseRepository;
import com.hoopsacademy.core.application.port.EntitlementService;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.roster.AssignPlayerToTeam;
import com.hoopsacademy.core.application.roster.AssignPlayerToTeam.Assignment;
import com.hoopsacademy.core.application.roster.PlayerStatusSync;
import com.hoopsacademy.core.application.roster.TenantToday;
import com.hoopsacademy.core.domain.eligibility.CaseResolution;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * The state changes behind add/withdraw, shared by the direct (ADMIN) path and the approval path. Methods join the
 * caller's transaction.
 */
@ApplicationScoped
public class PlayerLifecycle {

    public static final String EMAIL_TAKEN = "EMAIL_TAKEN";
    static final String WITHDRAWN_NOTE = "Player withdrawn";

    private final TenantContext tenantContext;
    private final EntitlementService entitlements;
    private final PersonRepository persons;
    private final PlayerRepository players;
    private final TeamPlayerRepository assignments;
    private final EligibilityCaseRepository cases;
    private final AssignPlayerToTeam assign;
    private final PlayerStatusSync statuses;
    private final TenantToday calendar;
    private final AuthzCache authzCache;
    private final Clock clock;

    public PlayerLifecycle(TenantContext tenantContext, EntitlementService entitlements, PersonRepository persons,
            PlayerRepository players, TeamPlayerRepository assignments, EligibilityCaseRepository cases,
            AssignPlayerToTeam assign, PlayerStatusSync statuses, TenantToday calendar, AuthzCache authzCache,
            Clock clock) {
        this.tenantContext = tenantContext;
        this.entitlements = entitlements;
        this.persons = persons;
        this.players = players;
        this.assignments = assignments;
        this.cases = cases;
        this.assign = assign;
        this.statuses = statuses;
        this.calendar = calendar;
        this.authzCache = authzCache;
        this.clock = clock;
    }

    /** Person (PLAYER role) + player row in {@code status}; 409 {@code EMAIL_TAKEN}, entitlement checked. */
    public PlayerId register(PersonalData data, PlayerStatus status) {
        entitlements.check(tenantContext.requireTenantId(), EntitlementService.Limit.PLAYERS);
        if (data.email() != null && persons.emailTaken(data.email(), Optional.empty())) {
            throw new ConflictException("A member with this e-mail already exists", EMAIL_TAKEN);
        }
        Person person = Person.create(PersonId.random(), data, Set.of(TenantRole.PLAYER), clock.instant());
        persons.insert(person);
        PlayerId player = players.create(person.id(), status);
        authzCache.invalidate(tenantContext.requireTenantId());
        return player;
    }

    /**
     * Makes a pending player ACTIVE, then assigns the optional team through the eligibility-checked command (422
     * {@code PLAYER_INELIGIBLE} propagates, rolling the transaction back). Without a team the player is an orphan.
     */
    public void admit(PlayerId player, Optional<TeamId> team, Optional<JerseyNumber> jersey) {
        players.updateStatus(player, PlayerStatus.ACTIVE);
        place(player, team, jersey);
    }

    /** Assignment of an ACTIVE player, or the orphan status when there is no team. */
    public void place(PlayerId player, Optional<TeamId> team, Optional<JerseyNumber> jersey) {
        if (team.isPresent()) {
            assign.assign(new Assignment(team.get(), player, jersey, Optional.empty()));
        } else {
            statuses.rederive(List.of(player), calendar.today());
        }
    }

    /**
     * Closes open assignments, resolves their OPEN eligibility cases (REMOVED_FROM_TEAM, the contract's closest
     * resolution) and marks the player WITHDRAWN. Idempotent.
     */
    public void withdraw(PlayerId player, PersonId by) {
        LocalDate today = calendar.today();
        assignments.openOfPlayers(List.of(player)).forEach(a -> assignments.update(a.close(today)));
        cases.openOfPlayer(player).forEach(
                c -> cases.update(c.resolve(CaseResolution.REMOVED_FROM_TEAM, by, WITHDRAWN_NOTE, clock.instant())));
        players.updateStatus(player, PlayerStatus.WITHDRAWN);
    }
}
