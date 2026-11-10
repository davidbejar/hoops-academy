package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.ContentLocale;
import com.hoopsacademy.athlete.domain.Exercise;
import com.hoopsacademy.athlete.domain.ExerciseId;
import com.hoopsacademy.athlete.domain.PlanId;
import com.hoopsacademy.athlete.domain.PlanItem;
import com.hoopsacademy.athlete.domain.PlanItemId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TrainingPlan;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Quick-add (decision 54, ADR-0041; decision 72, ADR-0047): catalogue exercises and items of any plan the tenant reads
 * (its plans, the global templates) are copied into a tenant plan or into a session's own plan, global content in the
 * caller's language; each copy keeps the exercise it came from. A session without a plan of its own gets one first,
 * starting with the items of the plan it referenced, so templates and shared plans never change.
 */
@ApplicationScoped
public class QuickAddItems {

    /** What one copy is made from. */
    public sealed interface ItemSource permits FromPlan, FromExercise {}

    /** An item of a readable plan or template. */
    public record FromPlan(PlanId planId, PlanItemId itemId) implements ItemSource {}

    /** A catalogue exercise (global or the academy's own); an archived one is refused. */
    public record FromExercise(ExerciseId exerciseId) implements ItemSource {}

    private final PlanRepository plans;
    private final ExerciseRepository exercises;
    private final SessionRepository sessions;
    private final PlanAccess planAccess;
    private final TrainingAccess trainingAccess;
    private final TenantClock clock;

    public QuickAddItems(PlanRepository plans, ExerciseRepository exercises, SessionRepository sessions,
            PlanAccess planAccess, TrainingAccess trainingAccess, TenantClock clock) {
        this.plans = plans;
        this.exercises = exercises;
        this.sessions = sessions;
        this.planAccess = planAccess;
        this.trainingAccess = trainingAccess;
        this.clock = clock;
    }

    /** Appends copies to a tenant plan (templates are read-only); returns the plan. */
    @Transactional
    public TrainingPlan toPlan(AuthzContext caller, PlanId target, List<ItemSource> refs, ContentLocale language) {
        planAccess.requireStaffRole(caller);
        TrainingPlan plan = plans.find(target).orElseThrow(() -> new NotFoundException("Plan not found"));
        plan.requireEditable();
        TrainingPlan changed = plan.withCopiesAppended(sources(refs, language), clock.now());
        plans.save(changed);
        return changed;
    }

    /** Appends copies to the session's own plan, creating it on the first quick-add; returns that plan. */
    @Transactional
    public TrainingPlan toSession(AuthzContext caller, Actor actor, SessionId sessionId, List<ItemSource> refs,
            ContentLocale language) {
        TrainingSession session = sessions.find(sessionId).orElseThrow(() -> new NotFoundException("Session not found"));
        trainingAccess.requireManage(caller, session.teamId());
        session.requireChangeable();
        List<PlanItem> copies = sources(refs, language);
        Optional<TrainingPlan> current = Optional.ofNullable(session.planId()).map(PlanId::new).flatMap(plans::find);
        TrainingPlan own = current.filter(plan -> plan.isAdHocFor(sessionId))
                .orElseGet(() -> current.map(plan -> plan.localized(language).adHocCopyFor(sessionId, actor, clock.now()))
                        .orElseGet(() -> TrainingPlan.forSession(sessionId, dayOf(caller, session), language, actor,
                                clock.now())));
        TrainingPlan changed = own.withCopiesAppended(copies, clock.now());
        plans.save(changed);
        if (!changed.id().value().equals(session.planId())) {
            sessions.save(session.withPlan(changed.id().value()));
        }
        return changed;
    }

    private LocalDate dayOf(AuthzContext caller, TrainingSession session) {
        return LocalDate.ofInstant(session.startsAt(), clock.zoneOf(caller.tenantId()));
    }

    /**
     * The items to copy, as the caller reads them, in the given order; an unknown or foreign plan, item or exercise is
     * a 404, an archived exercise a 422 ({@code EXERCISE_ARCHIVED}).
     */
    private List<PlanItem> sources(List<ItemSource> refs, ContentLocale language) {
        Map<PlanId, TrainingPlan> readablePlans = plans.findAll(idsOf(refs, FromPlan.class, FromPlan::planId))
                .stream().collect(Collectors.toMap(TrainingPlan::id, Function.identity()));
        Map<ExerciseId, Exercise> readableExercises = exercises.findAll(
                idsOf(refs, FromExercise.class, FromExercise::exerciseId))
                .stream().collect(Collectors.toMap(Exercise::id, Function.identity()));
        return refs.stream().map(ref -> switch (ref) {
            case FromPlan item -> found(readablePlans.get(item.planId()), "Plan").localized(language).item(item.itemId());
            case FromExercise exercise -> found(readableExercises.get(exercise.exerciseId()), "Exercise")
                    .localized(language).toItem();
        }).toList();
    }

    private static <S extends ItemSource, I> List<I> idsOf(List<ItemSource> refs, Class<S> kind, Function<S, I> id) {
        return refs.stream().filter(kind::isInstance).map(kind::cast).map(id).distinct().toList();
    }

    private static <T> T found(T readable, String what) {
        if (readable == null) {
            throw new NotFoundException(what + " not found");
        }
        return readable;
    }
}
