package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TeamStaffRepository;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.roster.StaffRole;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamStaffMember;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Team staff: any member reads, ADMIN attaches/detaches; every change invalidates the tenant's authz cache. */
@ApplicationScoped
public class TeamStaffService {

    public static final String ROLE_MISSING = "STAFF_ROLE_MISSING";

    /** A staff entry with the person's display name. */
    public record StaffView(TeamStaffMember member, String displayName) {}

    private final TenantContext tenantContext;
    private final TeamRepository teams;
    private final TeamStaffRepository staff;
    private final PersonRepository persons;
    private final AuthzCache authzCache;
    private final TenantToday calendar;
    private final PastSeasons pastSeasons;

    public TeamStaffService(TenantContext tenantContext, TeamRepository teams, TeamStaffRepository staff,
            PersonRepository persons, AuthzCache authzCache, TenantToday calendar, PastSeasons pastSeasons) {
        this.tenantContext = tenantContext;
        this.teams = teams;
        this.staff = staff;
        this.persons = persons;
        this.authzCache = authzCache;
        this.calendar = calendar;
        this.pastSeasons = pastSeasons;
    }

    @Transactional
    public List<StaffView> list(TeamId team) {
        requireTeam(team);
        List<TeamStaffMember> members = staff.ofTeam(team);
        Map<PersonId, String> names = persons.findAll(members.stream().map(TeamStaffMember::person).toList()).stream()
                .collect(Collectors.toMap(Person::id, Person::displayName));
        return members.stream().map(member -> new StaffView(member, names.getOrDefault(member.person(), ""))).toList();
    }

    /** Idempotent; the person must hold the tenant role matching {@code role} (422 {@code STAFF_ROLE_MISSING}). */
    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public StaffView put(TeamId team, PersonId personId, StaffRole role) {
        pastSeasons.requireOpenForAdmin(requireTeam(team));
        Person person = persons.find(personId).orElseThrow(() -> new NotFoundException("Person not found"));
        if (!person.roles().contains(role.tenantRole())) {
            throw new DomainRuleViolation("The person must hold the " + role.tenantRole() + " role", ROLE_MISSING);
        }
        TeamStaffMember member = staff.find(team, personId).map(existing -> existing.withRole(role))
                .orElseGet(() -> new TeamStaffMember(team, personId, role, calendar.today()));
        staff.save(member);
        authzCache.invalidate(tenantContext.requireTenantId());
        return new StaffView(member, person.displayName());
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public void remove(TeamId team, PersonId person) {
        pastSeasons.requireOpenForAdmin(requireTeam(team));
        staff.find(team, person).orElseThrow(() -> new NotFoundException("Staff member not found"));
        staff.delete(team, person);
        authzCache.invalidate(tenantContext.requireTenantId());
    }

    private Team requireTeam(TeamId team) {
        return teams.find(team).orElseThrow(() -> new NotFoundException("Team not found"));
    }
}
