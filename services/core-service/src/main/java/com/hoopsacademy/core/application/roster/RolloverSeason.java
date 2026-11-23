package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.PlayerRepository.PlayerSummary;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.domain.eligibility.Eligibility;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.eligibility.EligibilityEvaluator;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * {@code POST /seasons/{target}/rollover} (contract semantics, ADR-0014): clones every team of the source season into
 * the empty target season (name, alias, category, gender policy, optionally staff) and — unless
 * {@code clonePlayers=false} — the open assignments of ACTIVE/ORPHAN players, each evaluated with the target season's
 * reference year. Ineligible clones are invalidated (kept) with an OPEN case. The source season is left untouched.
 * Orphans = previously assigned active players without a valid assignment in the target season.
 */
@ApplicationScoped
public class RolloverSeason {

    public static final String SAME_SEASON = "ROLLOVER_SAME_SEASON";
    public static final String BACKWARDS = "ROLLOVER_BACKWARDS";
    public static final String TARGET_NOT_EMPTY = "ROLLOVER_TARGET_NOT_EMPTY";

    /** Contract {@code SeasonRolloverRequest}. */
    public record RolloverCommand(SeasonId from, boolean cloneStaff, boolean clonePlayers) {}

    /** An active player left without a valid assignment in the target season. */
    public record Orphan(PlayerId player, String displayName, Team previousTeam, List<EligibilityReason> reasons) {}

    /** Contract {@code SeasonRolloverResult}. */
    public record RolloverResult(SeasonId from, SeasonId to, List<Team> clonedTeams, List<Orphan> orphans,
            List<EligibilityCaseId> openedCases) {}

    private final TenantContext tenantContext;
    private final SeasonRepository seasons;
    private final TeamRepository teams;
    private final TeamStaffRepository staff;
    private final TeamPlayerRepository assignments;
    private final PlayerRepository players;
    private final EligibilityEngine engine;
    private final PlayerStatusSync statuses;
    private final AuthzCache authzCache;
    private final TenantToday calendar;

    public RolloverSeason(TenantContext tenantContext, SeasonRepository seasons, TeamRepository teams,
            TeamStaffRepository staff, TeamPlayerRepository assignments, PlayerRepository players,
            EligibilityEngine engine, PlayerStatusSync statuses, AuthzCache authzCache, TenantToday calendar) {
        this.tenantContext = tenantContext;
        this.seasons = seasons;
        this.teams = teams;
        this.staff = staff;
        this.assignments = assignments;
        this.players = players;
        this.engine = engine;
        this.statuses = statuses;
        this.authzCache = authzCache;
        this.calendar = calendar;
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public RolloverResult rollover(SeasonId targetId, RolloverCommand command) {
        Season target = season(targetId);
        Season source = season(command.from());
        requireForward(source, target);
        LocalDate today = calendar.today();
        Run run = new Run(target, command, today, engine.evaluator());
        List<Team> sourceTeams = teams.inSeasons(List.of(source.id()));
        List<TeamId> sourceIds = sourceTeams.stream().map(Team::id).toList();
        // one read each for all source teams (CORE-02), grouped in the per-team order of ofTeam
        Map<TeamId, List<TeamPlayer>> open = assignments.openOfTeams(sourceIds).stream()
                .collect(Collectors.groupingBy(TeamPlayer::team));
        Map<TeamId, List<TeamStaffMember>> staffOf = command.cloneStaff()
                ? staff.ofTeams(sourceIds).stream().collect(Collectors.groupingBy(TeamStaffMember::team))
                : Map.of();
        Map<PlayerId, PlayerSummary> summaries = players.summaries(
                open.values().stream().flatMap(List::stream).map(TeamPlayer::player).distinct().toList());
        for (Team team : sourceTeams) {
            run.cloneTeam(team, staffOf.getOrDefault(team.id(), List.of()), open.getOrDefault(team.id(), List.of()),
                    summaries);
        }
        if (command.cloneStaff()) {
            authzCache.invalidate(tenantContext.requireTenantId());
        }
        statuses.rederive(run.previousTeam.keySet(), today);
        return new RolloverResult(source.id(), target.id(), run.cloned, run.orphans(), run.opened);
    }

    private void requireForward(Season source, Season target) {
        if (source.id().equals(target.id())) {
            throw new DomainRuleViolation("A season cannot be rolled over into itself", SAME_SEASON);
        }
        if (!source.startsOn().isBefore(target.startsOn())) {
            throw new DomainRuleViolation("The target season must start after the source season", BACKWARDS);
        }
        if (!teams.inSeasons(List.of(target.id())).isEmpty()) {
            throw new ConflictException("The target season already has teams", TARGET_NOT_EMPTY);
        }
    }

    private Season season(SeasonId id) {
        return seasons.require(id);
    }

    /** State of one rollover. */
    private final class Run {

        private final Season target;
        private final RolloverCommand command;
        private final LocalDate today;
        private final LocalDate evaluatedOn;
        private final EligibilityEvaluator evaluator;
        private final List<Team> cloned = new ArrayList<>();
        private final List<EligibilityCaseId> opened = new ArrayList<>();
        private final Map<PlayerId, Team> previousTeam = new LinkedHashMap<>();
        private final Map<PlayerId, Set<EligibilityReason>> reasons = new LinkedHashMap<>();
        private final Map<PlayerId, String> names = new LinkedHashMap<>();
        private final Set<PlayerId> placed = new HashSet<>();

        Run(Season target, RolloverCommand command, LocalDate today, EligibilityEvaluator evaluator) {
            this.target = target;
            this.command = command;
            this.today = today;
            this.evaluatedOn = today.isBefore(target.startsOn()) ? target.startsOn() : today;
            this.evaluator = evaluator;
        }

        void cloneTeam(Team team, List<TeamStaffMember> members, List<TeamPlayer> open,
                Map<PlayerId, PlayerSummary> summaries) {
            Team clone = team.cloneInto(target.id());
            teams.insert(clone);
            cloned.add(clone);
            members.forEach(member -> staff.save(member.forTeam(clone.id(), today)));
            for (TeamPlayer assignment : open) {
                PlayerSummary player = summaries.get(assignment.player());
                if (player.candidate().isActive()) {
                    previousTeam.putIfAbsent(player.id(), team);
                    names.put(player.id(), player.displayName());
                    reasons.computeIfAbsent(player.id(), id -> new LinkedHashSet<>());
                    if (command.clonePlayers()) {
                        carryOver(assignment, player, clone);
                    }
                }
            }
        }

        private void carryOver(TeamPlayer assignment, PlayerSummary player, Team clone) {
            Eligibility verdict = evaluator.evaluate(player.candidate(), clone, target, evaluatedOn).eligibility();
            TeamPlayer copy = TeamPlayer.assign(clone.id(), player.id(), assignment.jersey(), target.startsOn(),
                    verdict.playUpLevels());
            assignments.insert(copy);
            if (verdict instanceof Eligibility.Ineligible ineligible) {
                opened.add(engine.invalidate(copy, ineligible.primaryReason()).id());
                reasons.get(player.id()).addAll(ineligible.reasons());
            } else {
                placed.add(player.id());
            }
        }

        List<Orphan> orphans() {
            return previousTeam.entrySet().stream().filter(entry -> !placed.contains(entry.getKey()))
                    .map(entry -> new Orphan(entry.getKey(), names.get(entry.getKey()), entry.getValue(),
                            List.copyOf(reasons.get(entry.getKey()))))
                    .toList();
        }
    }
}
