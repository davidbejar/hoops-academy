package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.ContentLocale;
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
 * Quick-add (decision 54, ADR-0041): items of any plan the tenant reads (its plans, the global templates) are copied
 * into a tenant plan or into a session's own plan, a template's in the caller's language. A session without a plan of
 * its own gets one first, starting with the items of the plan it referenced, so templates and shared plans never
 * change.
 */
@ApplicationScoped
public class QuickAddItems {

    /** One item to copy: the plan it is read from and its id. */
    public record ItemRef(PlanId planId, PlanItemId itemId) {}

    private final PlanRepository plans;
    private final SessionRepository sessions;
    private final PlanAccess planAccess;
    private final TrainingAccess trainingAccess;
    private final TenantClock clock;

    public QuickAddItems(PlanRepository plans, SessionRepository sessions, PlanAccess planAccess,
            TrainingAccess trainingAccess, TenantClock clock) {
        this.plans = plans;
        this.sessions = sessions;
        this.planAccess = planAccess;
        this.trainingAccess = trainingAccess;
        this.clock = clock;
    }

    /** Appends copies to a tenant plan (templates are read-only); returns the plan. */
    @Transactional
    public TrainingPlan toPlan(AuthzContext caller, PlanId target, List<ItemRef> refs, ContentLocale language) {
        planAccess.requireStaffRole(caller);
        TrainingPlan plan = plans.find(target).orElseThrow(() -> new NotFoundException("Plan not found"));
        plan.requireEditable();
        TrainingPlan changed = plan.withCopiesAppended(sources(refs, language), clock.now());
        plans.save(changed);
        return changed;
    }

    /** Appends copies to the session's own plan, creating it on the first quick-add; returns that plan. */
    @Transactional
    public TrainingPlan toSession(AuthzContext caller, Actor actor, SessionId sessionId, List<ItemRef> refs,
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

    /** The items to copy, as the caller reads them; an unknown or foreign plan or item is a 404. */
    private List<PlanItem> sources(List<ItemRef> refs, ContentLocale language) {
        Map<PlanId, TrainingPlan> readable = plans.findAll(refs.stream().map(ItemRef::planId).distinct().toList())
                .stream().collect(Collectors.toMap(TrainingPlan::id, Function.identity()));
        return refs.stream().map(ref -> {
            TrainingPlan plan = readable.get(ref.planId());
            if (plan == null) {
                throw new NotFoundException("Plan not found");
            }
            return plan.localized(language).item(ref.itemId());
        }).toList();
    }
}
