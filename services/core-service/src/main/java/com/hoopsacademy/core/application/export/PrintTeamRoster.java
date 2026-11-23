package com.hoopsacademy.core.application.export;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.RosterPrinter;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.export.ExportLimit;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

/**
 * GET /api/core/teams/{id}/roster:export with {@code Accept: application/pdf} (decision 89, WP116, ADR-0048
 * amendment): the roster {@link ExportTeamRoster} gathers for the same callers, printed by pdf-service (ADR-0051 §3)
 * under the academy's name, the team's season and category, in the caller's language. A roster larger than the sheet
 * is refused (422) before anything is sent. The audit row ({@code format} {@code pdf}) is written after the sheet came
 * back, in the same transaction: a refusal or a failed render (503) audits nothing.
 */
@ApplicationScoped
public class PrintTeamRoster {

    private final ExportTeamRoster roster;
    private final TeamRepository teams;
    private final SeasonRepository seasons;
    private final AgeCategoryRepository categories;
    private final TenantProfileRepository profiles;
    private final RosterPrinter printer;
    private final AuditLog audit;

    public PrintTeamRoster(ExportTeamRoster roster, TeamRepository teams, SeasonRepository seasons,
            AgeCategoryRepository categories, TenantProfileRepository profiles, RosterPrinter printer,
            AuditLog audit) {
        this.roster = roster;
        this.teams = teams;
        this.seasons = seasons;
        this.categories = categories;
        this.profiles = profiles;
        this.printer = printer;
        this.audit = audit;
    }

    /** The printed sheet and the roster it shows (for the file name). */
    public record PrintedRoster(RosterSheet sheet, byte[] pdf) {}

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public PrintedRoster print(TeamId teamId, AppLocale language) {
        RosterSheet sheet = roster.gather(teamId);
        ExportLimit.requirePrintable(sheet.players().size(), sheet.staff().size(), sheet.mostGuardians());
        byte[] pdf = printer.print(heading(teamId, sheet, language));
        audit.record(ExportTeamRoster.exported(teamId, sheet, ExportFormat.PDF));
        return new PrintedRoster(sheet, pdf);
    }

    private RosterPrint heading(TeamId teamId, RosterSheet sheet, AppLocale language) {
        Team team = teams.require(teamId);
        String season = seasons.find(team.season()).orElseThrow().name();
        String category = categories.find(team.category()).map(AgeCategory::name).orElse(null);
        TenantProfile academy = profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
        return new RosterPrint(sheet, academy.name(), season, category, language);
    }
}
