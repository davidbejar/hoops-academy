package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.membership.PersonId;
import java.util.Set;
import java.util.UUID;

/** Teams a person is staff of in the bound tenant. WP3 has no team tables: the default answers empty, WP4 replaces it. */
public interface StaffTeamsQuery {

    Set<UUID> staffTeamsOf(PersonId person);
}
