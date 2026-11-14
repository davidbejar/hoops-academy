package com.hoopsacademy.core.application.export;

import com.hoopsacademy.common.authz.Authz;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.export.RosterSheet.PlayerLine;
import com.hoopsacademy.core.application.export.RosterSheet.StaffLine;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.GuardianLinkRepository;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.application.roster.EligibilityEngine;
import com.hoopsacademy.core.domain.eligibility.EligibilityEvaluator;
import com.hoopsacademy.core.domain.export.ExportLimit;
import com.hoopsacademy.core.domain.membership.GuardianLink;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * GET /api/core/teams/{id}/roster:export (decisions 67 and 68, ADR-0048): the team's open assignments with each
 * player's person data, natural category in the team's season and active guardians, then the team's staff. ADMIN, or
 * a COACH who is current staff of the team (decision 83: a former coach of an ended season keeps its screens, ADR-0042,
 * but not its guardians' contact data); any other member 403. Every export is audited as
 * {@code team.roster_exported} with the row count only.
 */
@ApplicationScoped
public class ExportTeamRoster {

    private static final Comparator<Person> BY_NAME = Comparator
            .comparing((Person p) -> p.data().familyName(), String.CASE_INSENSITIVE_ORDER)
            .thenComparing(p -> p.data().givenName(), String.CASE_INSENSITIVE_ORDER);

    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final TeamPlayerRepository assignments;
    private final TeamStaffRepository staff;
    private final PlayerRepository players;
    private final PersonRepository persons;
    private final GuardianLinkRepository guardians;
    private final EligibilityEngine engine;
    private final ExportOrigins origins;
    private final Authz authz;
    private final AuditLog audit;

    public ExportTeamRoster(TeamRepository teams, SeasonRepository seasons, TeamPlayerRepository assignments,
            TeamStaffRepository staff, PlayerRepository players, PersonRepository persons,
            GuardianLinkRepository guardians, EligibilityEngine engine, ExportOrigins origins, Authz authz,
            AuditLog audit) {
        this.teams = teams;
        this.seasons = seasons;
        this.assignments = assignments;
        this.staff = staff;
        this.players = players;
        this.persons = persons;
        this.guardians = guardians;
        this.engine = engine;
        this.origins = origins;
        this.authz = authz;
        this.audit = audit;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public RosterSheet export(TeamId teamId) {
        Team team = teams.find(teamId).orElseThrow(() -> new NotFoundException("Team not found"));
        boolean currentCoach = authz.hasAnyRole(TenantRole.COACH) && authz.isStaffOf(teamId.value());
        authz.require(authz.isAdmin() || currentCoach, "Only ADMIN or the team's current coach may export its roster");
        List<TeamPlayer> open = assignments.ofTeam(teamId, false);
        List<TeamStaffMember> members = staff.ofTeam(teamId);
        ExportLimit.requireWithin((long) open.size() + members.size());
        ExportOrigin origin = origins.current();
        RosterSheet sheet = new RosterSheet(origin, team.name(), playerLines(team, open, origin),
                staffLines(members));
        audit.record(AuditEvent.of(AuditAction.TEAM_ROSTER_EXPORTED, teamId.value(), Map.of("rows", sheet.rows())));
        return sheet;
    }

    private List<PlayerLine> playerLines(Team team, List<TeamPlayer> open, ExportOrigin origin) {
        List<PlayerId> ids = open.stream().map(TeamPlayer::player).toList();
        Map<PlayerId, PlayerSummary> summaries = players.summaries(ids);
        List<GuardianLink> links = guardians.ofPlayers(ids);
        Map<PersonId, Person> people = personsById(Stream.concat(summaries.values().stream().map(PlayerSummary::person),
                links.stream().map(GuardianLink::guardian)).toList());
        Map<PlayerId, List<Person>> guardiansOf = links.stream()
                .filter(link -> people.containsKey(link.guardian()) && people.get(link.guardian()).active())
                .collect(Collectors.groupingBy(GuardianLink::player,
                        Collectors.mapping(link -> people.get(link.guardian()), Collectors.toList())));
        Season season = seasons.find(team.season()).orElseThrow();
        EligibilityEvaluator evaluator = engine.evaluator();
        return open.stream().map(assignment -> {
            PlayerSummary player = summaries.get(assignment.player());
            return new PlayerLine(people.get(player.person()),
                    evaluator.evaluate(player.candidate(), team, season, origin.day()).naturalCategory(), assignment,
                    guardiansOf.getOrDefault(player.id(), List.of()).stream().sorted(BY_NAME).toList());
        }).sorted(Comparator.comparing(PlayerLine::person, BY_NAME)).toList();
    }

    private List<StaffLine> staffLines(List<TeamStaffMember> members) {
        Map<PersonId, Person> people = personsById(members.stream().map(TeamStaffMember::person).toList());
        return members.stream().map(member -> new StaffLine(member, people.get(member.person())))
                .sorted(Comparator.comparing((StaffLine line) -> line.member().role())
                        .thenComparing(StaffLine::person, BY_NAME))
                .toList();
    }

    private Map<PersonId, Person> personsById(Collection<PersonId> ids) {
        return ids.isEmpty() ? Map.of() : persons.findAll(ids).stream()
                .collect(Collectors.toMap(Person::id, Function.identity(), (a, b) -> a));
    }
}
