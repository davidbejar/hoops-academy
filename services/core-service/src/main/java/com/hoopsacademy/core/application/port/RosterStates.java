package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * The current state of each roster aggregate as the event contracts publish it (libs/contracts/events), read fresh
 * from the database at the end of the bound tenant's transaction, after its changes are flushed. Each read takes the
 * row lock that serialises the writers of that aggregate's state (see the implementation), so two transactions that
 * change the same aggregate append their events in commit order and the later one sees the earlier one's change.
 * Empty: the aggregate does not exist (any more) in the bound tenant.
 */
public interface RosterStates {

    record PersonState(String displayName, Optional<String> subject, Set<TenantRole> roles, boolean active,
            Optional<PlayerId> player) {}

    record PlayerState(PersonId person, String displayName, PlayerStatus status, Optional<LocalDate> birthDate,
            Optional<Gender> gender) {}

    record TeamState(SeasonId season, LocalDate seasonStart, LocalDate seasonEnd, String name, Optional<String> alias,
            AgeCategoryId ageCategory, GenderPolicy genderPolicy) {}

    record TeamPlayerState(TeamId team, PlayerId player, Optional<String> jerseyNumber, LocalDate joinedOn,
            Optional<LocalDate> leftOn, int playUpLevels, Optional<EligibilityReason> invalidReason) {}

    record TeamStaffState(StaffRole role, LocalDate since) {}

    record GuardianLinkState(PersonId guardian, PlayerId player) {}

    record TenantState(String slug, String name, TenantStatus status, ZoneId timezone, AppLocale defaultLocale) {}

    Optional<PersonState> person(PersonId id);

    Optional<PlayerState> player(PlayerId id);

    Optional<TeamState> team(TeamId id);

    /** The teams of a season (their state carries the season's dates). */
    List<TeamId> teamsOfSeason(SeasonId season);

    Optional<TeamPlayerState> teamPlayer(TeamPlayerId id);

    Optional<TeamStaffState> teamStaff(TeamId team, PersonId person);

    Optional<GuardianLinkState> guardianLink(GuardianLinkId id);

    /** The bound tenant. */
    Optional<TenantState> tenant();
}
