package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.identity.TemporaryPasswordStatus;
import com.hoopsacademy.core.domain.identity.UserId;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * When a login's temporary password was issued and expired ({@code core.app_user}, global, ADR-0028). Every method
 * runs in the caller's transaction; none needs a bound tenant.
 */
public interface TemporaryPasswordLogins {

    /**
     * Records a newly issued temporary password of {@code subject} (issue time {@code at}, no expiry).
     *
     * @return true when the previous one had expired, i.e. the sweep disabled the login
     * @throws IllegalStateException when the login is not registered
     */
    boolean issued(String subject, Instant at);

    /** The subjects whose temporary password was issued before {@code issuedBefore} and has not expired. */
    List<String> due(Instant issuedBefore);

    /**
     * Locks the login row of {@code subject} for the rest of the transaction if it is still due (re-checked under the
     * lock, so a concurrent re-issue wins); empty when it is not due any more.
     */
    Optional<UserId> lockIfDue(String subject, Instant issuedBefore);

    void expired(String subject, Instant at);

    /** Forgets the issue time: the person has a password of their own now, nothing is left to expire. */
    void used(String subject);

    /** The status of each login in {@code logins} (missing ids are absent from the map). */
    Map<UserId, TemporaryPasswordStatus> statusOf(Collection<UserId> logins);
}
