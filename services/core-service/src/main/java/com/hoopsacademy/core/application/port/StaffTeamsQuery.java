package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.membership.PersonId;
import java.util.Set;
import java.util.UUID;

/** Teams a person is staff of in the bound tenant (team_staff; implemented by {@code application.roster.StaffTeams}). */
public interface StaffTeamsQuery {

    Set<UUID> staffTeamsOf(PersonId person);
}
