package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.AgeAt;
import com.hoopsacademy.athlete.domain.BandResolver;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.PhysicalTestResult;
import com.hoopsacademy.athlete.domain.PhysicalTestType;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TestResultId;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalInt;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Physical test results. ADMIN and staff of the player's team write; guardians and the player read. Every result is
 * returned with the player's age on the day of the test and the band expected for it (tenant norms over global ones).
 */
@ApplicationScoped
public class ManageTestResults {

    public record NewResult(PlayerId playerId, TestTypeId testTypeId, LocalDate measuredOn, BigDecimal value, String notes) {}

    public record ResultChange(Optional<LocalDate> measuredOn, Optional<BigDecimal> value, Optional<Optional<String>> notes) {}

    public record Search(Optional<PlayerId> player, Optional<TeamId> team, Optional<TestTypeId> testType,
            Optional<LocalDate> from, Optional<LocalDate> to, int page, int size) {}

    /** A result with what was derived for it; {@code ageAtMeasurement} is empty when the birth date is unknown. */
    public record ResultView(PhysicalTestResult result, PhysicalTestType type, OptionalInt ageAtMeasurement,
            BandResolver.Resolution resolution) {}

    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);

    private final TestResultRepository results;
    private final TestTypeRepository types;
    private final NormRepository norms;
    private final RosterPort roster;
    private final HealthAccess access;
    private final TenantClock clock;

    public ManageTestResults(TestResultRepository results, TestTypeRepository types, NormRepository norms, RosterPort roster,
            HealthAccess access, TenantClock clock) {
        this.results = results;
        this.types = types;
        this.norms = norms;
        this.roster = roster;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public ResultView create(AuthzContext caller, Actor actor, NewResult request) {
        access.requireManage(caller, request.playerId());
        if (!roster.playerExists(caller.tenantId(), request.playerId())) {
            throw new NotFoundException("Player not found");
        }
        types.find(request.testTypeId()).orElseThrow(() -> new NotFoundException("Test type not found"));
        PhysicalTestResult result = PhysicalTestResult.record(request.playerId(), request.testTypeId(), request.measuredOn(),
                request.value(), request.notes(), actor, clock.now());
        results.save(result);
        return view(caller, List.of(result)).get(0);
    }

    @Transactional
    public ResultView get(AuthzContext caller, TestResultId id) {
        return view(caller, List.of(load(caller, id))).get(0);
    }

    @Transactional
    public ResultView update(AuthzContext caller, TestResultId id, ResultChange change) {
        PhysicalTestResult current = load(caller, id);
        access.requireManage(caller, current.playerId());
        PhysicalTestResult changed = current.changedTo(change.measuredOn().orElse(current.measuredOn()),
                change.value().orElse(current.value()), Patches.apply(change.notes(), current.notes()), clock.now());
        results.save(changed);
        return view(caller, List.of(changed)).get(0);
    }

    @Transactional
    public void delete(AuthzContext caller, TestResultId id) {
        PhysicalTestResult current = load(caller, id);
        access.requireManage(caller, current.playerId());
        results.delete(id);
    }

    @Transactional
    public PageResult<ResultView> search(AuthzContext caller, Search search) {
        HealthAccess.Scope scope = access.listScope(caller, search.player(), search.team());
        PageResult<PhysicalTestResult> page = results.search(scope.players(), search.testType(),
                search.from().orElse(MIN_DATE), scope.cap(search.to().orElse(MAX_DATE)),
                search.page(), search.size());
        List<ResultView> views = view(caller, page.items());
        return new PageResult<>(views, page.page(), page.size(), page.totalElements());
    }

    private PhysicalTestResult load(AuthzContext caller, TestResultId id) {
        PhysicalTestResult result = results.find(id).orElseThrow(() -> new NotFoundException("Test result not found"));
        access.requireRead(caller, result.playerId(), result.measuredOn(), "Test result");
        return result;
    }

    /** Resolves players, types and norms once for the whole batch. */
    private List<ResultView> view(AuthzContext caller, List<PhysicalTestResult> items) {
        if (items.isEmpty()) {
            return List.of();
        }
        Set<PlayerId> players = items.stream().map(PhysicalTestResult::playerId).collect(Collectors.toCollection(HashSet::new));
        Set<TestTypeId> typeIds = items.stream().map(PhysicalTestResult::testTypeId).collect(Collectors.toCollection(HashSet::new));
        Map<PlayerId, PlayerBrief> briefs = roster.players(caller.tenantId(), players);
        Map<TestTypeId, PhysicalTestType> typesById = types.findAll(typeIds);
        Map<TestTypeId, List<PhysicalTestNorm>> normsByType = norms.forTypes(typeIds).stream()
                .collect(Collectors.groupingBy(PhysicalTestNorm::testTypeId));
        return items.stream().map(result -> {
            PlayerBrief brief = briefs.get(result.playerId());
            Optional<LocalDate> birth = Optional.ofNullable(brief).flatMap(PlayerBrief::birthDate);
            OptionalInt age = birth.map(b -> OptionalInt.of(AgeAt.years(b, result.measuredOn()))).orElse(OptionalInt.empty());
            var resolution = BandResolver.resolve(normsByType.getOrDefault(result.testTypeId(), List.of()),
                    Optional.ofNullable(brief).flatMap(PlayerBrief::gender), age, result.value());
            return new ResultView(result, typesById.get(result.testTypeId()), age, resolution);
        }).toList();
    }
}
