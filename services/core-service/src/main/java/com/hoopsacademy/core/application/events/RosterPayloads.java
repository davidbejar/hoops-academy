package com.hoopsacademy.core.application.events;

import com.hoopsacademy.core.application.port.RosterStates.GuardianLinkState;
import com.hoopsacademy.core.application.port.RosterStates.PersonState;
import com.hoopsacademy.core.application.port.RosterStates.PlayerState;
import com.hoopsacademy.core.application.port.RosterStates.TeamPlayerState;
import com.hoopsacademy.core.application.port.RosterStates.TeamStaffState;
import com.hoopsacademy.core.application.port.RosterStates.TeamState;
import com.hoopsacademy.core.application.port.RosterStates.TenantState;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.tenant.Tenant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * The payload objects of the event contracts ({@code $defs/<Aggregate>Changed|Removed} in libs/contracts/events): every
 * field present, an absent value as an explicit null, field names as in the schema.
 */
final class RosterPayloads {

    private RosterPayloads() {}

    static Map<String, Object> person(PersonState state) {
        return fields("displayName", state.displayName(), "subject", state.subject(),
                "roles", state.roles().stream().map(Enum::name).sorted().toList(), "active", state.active());
    }

    static Map<String, Object> player(PlayerState state) {
        return fields("personId", state.person().value().toString(), "displayName", state.displayName(),
                "status", state.status().name(), "birthDate", state.birthDate().map(Object::toString),
                "gender", state.gender().map(Enum::name));
    }

    static Map<String, Object> team(TeamState state) {
        return fields("seasonId", state.season().value().toString(), "seasonStartDate", state.seasonStart().toString(),
                "seasonEndDate", state.seasonEnd().toString(), "name", state.name(), "alias", state.alias(),
                "ageCategoryId", state.ageCategory().value().toString(), "genderPolicy", state.genderPolicy().name());
    }

    static Map<String, Object> teamPlayer(TeamPlayerState state) {
        return fields("teamId", state.team().value().toString(), "playerId", state.player().value().toString(),
                "jerseyNumber", state.jerseyNumber(), "joinedOn", state.joinedOn().toString(),
                "leftOn", state.leftOn().map(Object::toString), "playUpLevels", state.playUpLevels(),
                "invalidReason", state.invalidReason().map(Enum::name));
    }

    static Map<String, Object> teamStaffIdentity(TeamId team, PersonId person) {
        return fields("teamId", team.value().toString(), "personId", person.value().toString());
    }

    static Map<String, Object> teamStaff(TeamId team, PersonId person, TeamStaffState state) {
        Map<String, Object> payload = new LinkedHashMap<>(teamStaffIdentity(team, person));
        payload.put("role", state.role().name());
        payload.put("since", state.since().toString());
        return Collections.unmodifiableMap(payload);
    }

    static Map<String, Object> guardianLink(GuardianLinkState state) {
        return fields("guardianPersonId", state.guardian().value().toString(),
                "playerId", state.player().value().toString());
    }

    static Map<String, Object> tenant(TenantState state) {
        return fields("slug", state.slug(), "name", state.name(), "status", state.status().name(),
                "timezone", state.timezone().getId(), "defaultLocale", state.defaultLocale().code());
    }

    /** The platform's view of a tenant (lifecycle and master data changes on the platform datasource). */
    static Map<String, Object> tenant(Tenant tenant) {
        return tenant(new TenantState(tenant.slug().value(), tenant.name(), tenant.status(), tenant.timezone(),
                tenant.defaultLocale()));
    }

    /** Name/value pairs in order; an {@link Optional} becomes its value or null. */
    private static Map<String, Object> fields(Object... namesAndValues) {
        Map<String, Object> payload = new LinkedHashMap<>();
        for (int i = 0; i < namesAndValues.length; i += 2) {
            Object value = namesAndValues[i + 1];
            payload.put((String) namesAndValues[i], value instanceof Optional<?> optional ? optional.orElse(null) : value);
        }
        return Collections.unmodifiableMap(payload);
    }
}
