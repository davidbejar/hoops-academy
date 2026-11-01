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

/** Test types: every member reads the global and the tenant's types, ADMIN defines and edits the tenant's own. */
@ApplicationScoped
public class ManageTestTypes {

    public record NewType(String code, String name, String unit, boolean higherIsBetter, String description) {}

    public record TypeChange(Optional<String> name, Optional<String> unit, Optional<Boolean> higherIsBetter,
            Optional<Optional<String>> description) {}

    private final TestTypeRepository types;

    public ManageTestTypes(TestTypeRepository types) {
        this.types = types;
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
        if (types.codeExists(type.code())) {
            throw new ConflictException("The test type code " + type.code() + " is already in use", "TEST_TYPE_CODE_EXISTS");
        }
        types.save(type);
        return type;
    }

    @Transactional
    public PhysicalTestType update(AuthzContext caller, TestTypeId id, TypeChange change) {
        requireAdmin(caller);
        PhysicalTestType current = get(id);
        PhysicalTestType changed = current.changedTo(change.name().orElse(current.name()), change.unit().orElse(current.unit()),
                change.higherIsBetter().orElse(current.higherIsBetter()),
                Patches.apply(change.description(), current.description()));
        types.save(changed);
        return changed;
    }

    private static void requireAdmin(AuthzContext caller) {
        if (!caller.hasRole(TenantRole.ADMIN)) {
            throw new AccessDeniedException("Only an administrator may manage test types");
        }
    }
}
