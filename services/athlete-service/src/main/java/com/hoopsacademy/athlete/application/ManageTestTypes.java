package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PhysicalTestType;
import com.hoopsacademy.athlete.domain.TestTypeId;
import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Optional;

/**
 * Test types: every member reads the global and the tenant's types; ADMIN defines, edits (code included) and deletes
 * the tenant's own. A type that results use is never deleted.
 */
@ApplicationScoped
public class ManageTestTypes {

    public record NewType(String code, String name, String unit, boolean higherIsBetter, String description) {}

    public record TypeChange(Optional<String> code, Optional<String> name, Optional<String> unit,
            Optional<Boolean> higherIsBetter, Optional<Optional<String>> description) {}

    private final TestTypeRepository types;
    private final TestResultRepository results;

    public ManageTestTypes(TestTypeRepository types, TestResultRepository results) {
        this.types = types;
        this.results = results;
    }

    @Transactional
    public List<PhysicalTestType> list() {
        return types.list();
    }

    @Transactional
    public PhysicalTestType get(TestTypeId id) {
        return types.find(id).orElseThrow(() -> new NotFoundException("Test type not found"));
    }

    @Transactional
    public PhysicalTestType create(AuthzContext caller, NewType request) {
        requireAdmin(caller);
        PhysicalTestType type = PhysicalTestType.custom(request.code(), request.name(), request.unit(),
                request.higherIsBetter(), request.description());
        requireUnusedCode(type.code());
        types.save(type);
        return type;
    }

    @Transactional
    public PhysicalTestType update(AuthzContext caller, TestTypeId id, TypeChange change) {
        requireAdmin(caller);
        PhysicalTestType current = get(id);
        PhysicalTestType changed = current.changedTo(change.code().orElse(current.code()),
                change.name().orElse(current.name()), change.unit().orElse(current.unit()),
                change.higherIsBetter().orElse(current.higherIsBetter()),
                Patches.apply(change.description(), current.description()));
        if (!changed.code().equals(current.code())) {
            requireUnusedCode(changed.code());
        }
        types.save(changed);
        return changed;
    }

    /** Global types and other tenants' types are not found (404); a type with results is a 409. */
    @Transactional
    public void delete(AuthzContext caller, TestTypeId id) {
        requireAdmin(caller);
        PhysicalTestType type = types.find(id).filter(t -> !t.global())
                .orElseThrow(() -> new NotFoundException("Test type not found"));
        if (results.existsForType(type.id())) {
            throw new ConflictException("The test type " + type.code() + " has results and cannot be deleted",
                    "TEST_TYPE_HAS_RESULTS");
        }
        types.delete(type.id());
    }

    private void requireUnusedCode(String code) {
        if (types.codeExists(code)) {
            throw new ConflictException("The test type code " + code + " is already in use", "TEST_TYPE_CODE_EXISTS");
        }
    }

    private static void requireAdmin(AuthzContext caller) {
        if (!caller.hasRole(TenantRole.ADMIN)) {
            throw new AccessDeniedException("Only an administrator may manage test types");
        }
    }
}
