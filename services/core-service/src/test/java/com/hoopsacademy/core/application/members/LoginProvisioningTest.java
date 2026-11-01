package com.hoopsacademy.core.application.members;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.core.application.port.IdentityProviderException;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class LoginProvisioningTest {

    private final RecordingIdentityProvider identityProvider = new RecordingIdentityProvider();
    private final LoginProvisioning logins = new LoginProvisioning(identityProvider);

    @Test
    void successKeepsTheLogin() {
        assertThat(logins.compensateOnFailure(new ProvisionedIdentity("s1", true), () -> "ok")).isEqualTo("ok");
        assertThat(identityProvider.deleted).isEmpty();
    }

    @Test
    void failureDeletesOnlyALoginThisCallCreated() {
        RuntimeException boom = new IllegalStateException("db down");
        assertThatThrownBy(() -> logins.compensateOnFailure(new ProvisionedIdentity("new", true), () -> {
            throw boom;
        })).isSameAs(boom);
        assertThatThrownBy(() -> logins.compensateOnFailure(new ProvisionedIdentity("existing", false), () -> {
            throw boom;
        })).isSameAs(boom);
        assertThat(identityProvider.deleted).containsExactly("new");
    }

    @Test
    void aFailingCompensationIsAttachedToTheOriginalFailure() {
        identityProvider.failDeletes = true;
        RuntimeException boom = new IllegalStateException("db down");
        assertThatThrownBy(() -> logins.compensateOnFailure(new ProvisionedIdentity("new", true), () -> {
            throw boom;
        })).isSameAs(boom).satisfies(e -> assertThat(e.getSuppressed()).hasSize(1));
    }

    @Test
    void provisionDelegates() {
        assertThat(logins.provision(new NewIdentity("a@example.com", "A", "B", null)))
                .isEqualTo(new ProvisionedIdentity("sub-a@example.com", true));
    }

    private static final class RecordingIdentityProvider implements IdentityProviderPort {
        final List<String> deleted = new ArrayList<>();
        boolean failDeletes;

        @Override
        public ProvisionedIdentity provision(NewIdentity identity) {
            return new ProvisionedIdentity("sub-" + identity.email(), true);
        }

        @Override
        public void sendAccountSetupEmail(String subject) {}

        @Override
        public void delete(String subject) {
            if (failDeletes) {
                throw new IdentityProviderException("down");
            }
            deleted.add(subject);
        }
    }
}
