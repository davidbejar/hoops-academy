package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class TenantIdTest {

    @Test
    void parsesCanonicalUuid() {
        var raw = "6f1c2b9e-1d2a-4c3b-9e8f-0a1b2c3d4e5f";

        TenantId tenantId = TenantId.parse(raw);

        assertThat(tenantId.value()).isEqualTo(UUID.fromString(raw));
        assertThat(tenantId.toString()).isEqualTo(raw);
    }

    @Test
    void parsingIsCaseInsensitiveAndTrimmed() {
        assertThat(TenantId.parse("  6F1C2B9E-1D2A-4C3B-9E8F-0A1B2C3D4E5F "))
                .isEqualTo(TenantId.parse("6f1c2b9e-1d2a-4c3b-9e8f-0a1b2c3d4e5f"));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"not-a-uuid", "6f1c2b9e1d2a4c3b9e8f0a1b2c3d4e5f", "1-2-3-4-5", "6f1c2b9e-1d2a-4c3b-9e8f-0a1b2c3d4e5f0"})
    void rejectsAnythingButACanonicalUuid(String raw) {
        assertThatThrownBy(() -> TenantId.parse(raw)).isInstanceOf(InvalidTenantIdException.class);
    }

    @Test
    void requiresAValue() {
        assertThatThrownBy(() -> new TenantId(null)).isInstanceOf(NullPointerException.class);
    }
}
