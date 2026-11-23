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
    public List<EligibilityCase> openOfPlayer(PlayerId player) {
        return em.createQuery("select c, a.teamId" + FROM + " and c.playerId = :player and c.status = 'OPEN'",
                        Object[].class)
                .setParameter("player", player.value()).getResultStream()
                .map(row -> toView(row).eligibilityCase()).toList();
    }

    @Override
    public PageResult<CaseOfTeam> list(CaseFilter filter, PageRequest page) {
        if (filter.onlyTeams().filter(Collection::isEmpty).isPresent()) {
            return new PageResult<>(List.of(), page, 0);
        }
        return PagedQuery.of(em, "from EligibilityCaseEntity c, TeamPlayerEntity a", "c")
                .where("a.id = c.teamPlayerId")
                .whereIf(filter.status(), "c.status = :status", "status", CaseStatus::name)
                .whereIf(filter.team(), "a.teamId = :team", "team", TeamId::value)
                .whereIf(filter.player(), "c.playerId = :player", "player", PlayerId::value)
                .whereIf(filter.onlyTeams(), "a.teamId in :teams", "teams",
                        ids -> ids.stream().map(TeamId::value).toList())
                .orderBy("c.createdAt desc, c.id")
                .page(page, "select c, a.teamId", Object[].class, JpaEligibilityCaseRepository::toView);
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
