package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.membership.GuardianLink;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.util.Optional;
import java.util.Set;

/** Guardian ↔ player links of the bound tenant. */
public interface GuardianLinkRepository {

    void insert(GuardianLink link);

    boolean exists(PersonId guardian, PlayerId player);

    Optional<GuardianLink> find(GuardianLinkId id);

    void delete(GuardianLinkId id);

    PageResult<GuardianLink> list(Optional<PlayerId> player, Optional<PersonId> guardian, PageRequest page);

    Set<PlayerId> playersOf(PersonId guardian);
}
