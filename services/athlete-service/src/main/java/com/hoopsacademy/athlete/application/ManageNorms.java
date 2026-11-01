package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.BandResolver;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.NormBand;
import com.hoopsacademy.athlete.domain.NormId;
import com.hoopsacademy.athlete.domain.PhysicalTestNorm;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/** Reference norms: every member reads; ADMIN adds, replaces and deletes the tenant's own overriding rows. */
@ApplicationScoped
public class ManageNorms {

    public enum Scope { EFFECTIVE, GLOBAL, TENANT }

    public record NormFields(TestTypeId testTypeId, Gender gender, int minAge, int maxAge, NormBand band,
            BigDecimal minValue, BigDecimal maxValue, String source) {}

    private final NormRepository norms;
    private final TestTypeRepository types;

    public ManageNorms(NormRepository norms, TestTypeRepository types) {
        this.norms = norms;
        this.types = types;
    }

    @Transactional
    public List<PhysicalTestNorm> list(Scope scope, Optional<TestTypeId> type, Optional<Gender> gender) {
        List<PhysicalTestNorm> visible = norms.list(type, gender);
        return switch (scope) {
            case GLOBAL -> visible.stream().filter(PhysicalTestNorm::global).toList();
            case TENANT -> visible.stream().filter(n -> !n.global()).toList();
            case EFFECTIVE -> BandResolver.effective(visible).stream()
                    .sorted(java.util.Comparator.comparing((PhysicalTestNorm n) -> n.testTypeId().value())
                            .thenComparing(PhysicalTestNorm::gender).thenComparingInt(PhysicalTestNorm::minAge)
                            .thenComparing(PhysicalTestNorm::band))
                    .toList();
        };
    }

    @Transactional
    public PhysicalTestNorm create(AuthzContext caller, NormFields fields) {
        requireAdmin(caller);
        PhysicalTestNorm norm = build(NormId.random(), fields);
        save(norm);
        return norm;
    }

    @Transactional
    public PhysicalTestNorm replace(AuthzContext caller, NormId id, NormFields fields) {
        requireAdmin(caller);
        requireOwnNorm(id);
        PhysicalTestNorm norm = build(id, fields);
        save(norm);
        return norm;
    }

    @Transactional
    public void delete(AuthzContext caller, NormId id) {
        requireAdmin(caller);
        requireOwnNorm(id);
        norms.delete(id);
    }

    private PhysicalTestNorm build(NormId id, NormFields f) {
        types.find(f.testTypeId()).orElseThrow(() -> new NotFoundException("Test type not found"));
        boolean noSource = f.source() == null || f.source().isBlank();
        return PhysicalTestNorm.of(id, f.testTypeId(), f.gender(), f.minAge(), f.maxAge(), f.band(), f.minValue(), f.maxValue(),
                noSource, noSource ? null : f.source().trim(), false);
    }

    /** The same band of the same test and gender must not be defined twice for overlapping ages. */
    private void save(PhysicalTestNorm norm) {
        boolean overlap = norms.tenantNorms(norm.testTypeId(), norm.gender()).stream()
                .anyMatch(other -> !other.id().equals(norm.id()) && other.band() == norm.band() && other.overlapsAges(norm));
        if (overlap) {
            throw new ConflictException("The tenant already defines the " + norm.band() + " band for overlapping ages",
                    "NORM_RANGE_OVERLAP");
        }
        norms.save(norm);
    }

    private PhysicalTestNorm requireOwnNorm(NormId id) {
        PhysicalTestNorm existing = norms.find(id).orElseThrow(() -> new NotFoundException("Norm not found"));
        if (existing.global()) {
            throw new AccessDeniedException("Global norms are read-only; add a tenant norm to override them", "NORM_IS_GLOBAL");
        }
        return existing;
    }

    private static void requireAdmin(AuthzContext caller) {
        if (!caller.hasRole(TenantRole.ADMIN)) {
            throw new AccessDeniedException("Only an administrator may manage norms");
        }
    }
}
