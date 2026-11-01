package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.EligibilityCaseRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.eligibility.CaseResolution;
import com.hoopsacademy.core.domain.eligibility.CaseStatus;
import com.hoopsacademy.core.domain.eligibility.EligibilityCase;
import com.hoopsacademy.core.domain.eligibility.EligibilityCaseId;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
class JpaEligibilityCaseRepository implements EligibilityCaseRepository {

    private static final String FROM = " from EligibilityCaseEntity c, TeamPlayerEntity a where a.id = c.teamPlayerId";

    private final EntityManager em;

    JpaEligibilityCaseRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void insert(EligibilityCase eligibilityCase) {
        EligibilityCaseEntity row = new EligibilityCaseEntity();
        row.id = eligibilityCase.id().value();
        row.playerId = eligibilityCase.player().value();
        row.teamPlayerId = eligibilityCase.assignment().value();
        row.reason = eligibilityCase.reason().name();
        row.createdAt = eligibilityCase.openedAt();
        copyResolution(eligibilityCase, row);
        em.persist(row);
    }

    @Override
    public void update(EligibilityCase eligibilityCase) {
        copyResolution(eligibilityCase, em.find(EligibilityCaseEntity.class, eligibilityCase.id().value()));
    }

    @Override
    public Optional<CaseOfTeam> find(EligibilityCaseId id) {
        return em.createQuery("select c, a.teamId" + FROM + " and c.id = :id", Object[].class)
                .setParameter("id", id.value()).getResultStream().findFirst().map(JpaEligibilityCaseRepository::toView);
    }

    @Override
    public PageResult<CaseOfTeam> list(CaseFilter filter, PageRequest page) {
        if (filter.onlyTeams().filter(Collection::isEmpty).isPresent()) {
            return new PageResult<>(List.of(), page, 0);
        }
        List<String> conditions = new ArrayList<>();
        filter.status().ifPresent(s -> conditions.add("c.status = :status"));
        filter.team().ifPresent(t -> conditions.add("a.teamId = :team"));
        filter.player().ifPresent(p -> conditions.add("c.playerId = :player"));
        filter.onlyTeams().ifPresent(ids -> conditions.add("a.teamId in :teams"));
        String where = conditions.stream().map(condition -> " and " + condition).reduce("", String::concat);
        TypedQuery<Object[]> items = em.createQuery("select c, a.teamId" + FROM + where
                + " order by c.createdAt desc, c.id", Object[].class);
        TypedQuery<Long> total = em.createQuery("select count(c)" + FROM + where, Long.class);
        for (TypedQuery<?> query : List.of(items, total)) {
            filter.status().ifPresent(s -> query.setParameter("status", s.name()));
            filter.team().ifPresent(t -> query.setParameter("team", t.value()));
            filter.player().ifPresent(p -> query.setParameter("player", p.value()));
            filter.onlyTeams().ifPresent(ids -> query.setParameter("teams", ids.stream().map(TeamId::value).toList()));
        }
        List<CaseOfTeam> found = items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultStream()
                .map(JpaEligibilityCaseRepository::toView).toList();
        return new PageResult<>(found, page, total.getSingleResult());
    }

    private static void copyResolution(EligibilityCase source, EligibilityCaseEntity row) {
        row.status = source.status().name();
        row.resolution = source.resolution() == null ? null : source.resolution().name();
        row.resolutionNote = source.resolutionNote();
        row.resolvedByPersonId = source.resolvedBy() == null ? null : source.resolvedBy().value();
        row.resolvedAt = source.resolvedAt();
    }

    private static CaseOfTeam toView(Object[] row) {
        EligibilityCaseEntity c = (EligibilityCaseEntity) row[0];
        EligibilityCase domain = new EligibilityCase(new EligibilityCaseId(c.id), new PlayerId(c.playerId),
                new TeamPlayerId(c.teamPlayerId), EligibilityReason.valueOf(c.reason), CaseStatus.valueOf(c.status),
                c.createdAt, c.resolvedAt, c.resolvedByPersonId == null ? null : new PersonId(c.resolvedByPersonId),
                c.resolution == null ? null : CaseResolution.valueOf(c.resolution), c.resolutionNote);
        return new CaseOfTeam(domain, new TeamId((UUID) row[1]));
    }
}
