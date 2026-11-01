package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.members.LoginProvisioning;
import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.util.Optional;
import java.util.function.Function;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * A player with an e-mail gets a login once they are ACTIVE (contract {@code CreatePlayerRequest.email}): directly
 * when an ADMIN adds them, on approval when a COACH requested them. Reuses the invitation saga of
 * {@link LoginProvisioning}: Keycloak first, then the tenant transaction (setup e-mail last), and on failure the
 * login this call created is deleted.
 */
@ApplicationScoped
public class PlayerLogin {

    private final LoginProvisioning logins;
    private final MemberProvisioning provisioning;
    private final PersonRepository persons;
    private final PlayerRepository players;

    PlayerLogin(LoginProvisioning logins, MemberProvisioning provisioning, PersonRepository persons,
            PlayerRepository players) {
        this.logins = logins;
        this.provisioning = provisioning;
        this.persons = persons;
        this.players = players;
    }

    static Optional<NewIdentity> identityOf(PersonalData data) {
        return Optional.ofNullable(data.email())
                .map(email -> new NewIdentity(email, data.givenName(), data.familyName(), data.locale()));
    }

    /** Provisions the login (if any) before {@code databaseWork} and compensates when that work fails. */
    <T> T around(Optional<NewIdentity> identity, Function<Optional<ProvisionedIdentity>, T> databaseWork) {
        if (identity.isEmpty()) {
            return databaseWork.apply(Optional.empty());
        }
        ProvisionedIdentity login = logins.provision(identity.get());
        return logins.compensateOnFailure(login, () -> databaseWork.apply(Optional.of(login)));
    }

    /** Inside the tenant transaction: link the login to the player's person and index the membership. */
    void link(PlayerId player, ProvisionedIdentity login) {
        Person person = players.personOf(player).flatMap(persons::find)
                .orElseThrow(() -> new IllegalStateException("Player " + player + " has no person"));
        Person linked = provisioning.attachLogin(person, login);
        persons.update(linked);
        provisioning.indexMembership(login, linked);
    }

    /** The last step before commit: the setup e-mail for a login this call created. */
    void sendSetupEmail(Optional<ProvisionedIdentity> login) {
        provisioning.sendSetupEmail(login);
    }
}
