package com.hoopsacademy.game.application.sheet;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.AcademyNames;
import com.hoopsacademy.game.application.CurrentCaller;
import com.hoopsacademy.game.application.GetBoxScore;
import com.hoopsacademy.game.application.RosterPort;
import com.hoopsacademy.game.domain.MatchId;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * The match sheet PDF (contract getMatchSheetPdf; decisions 89 and 90): the caller's box score read through
 * {@link GetBoxScore} (same readers, same lines, 404 for an unknown match), the team's name from core, the academy's
 * name and zone, rendered by {@link MatchSheetRenderer}. Not transactional itself: the reads have their own
 * transactions and no database connection is held while pdf-service renders. Not audited (a read every member has).
 */
@ApplicationScoped
public class GetMatchSheetPdf {

    private final GetBoxScore boxScores;
    private final RosterPort roster;
    private final AcademyNames academies;
    private final CurrentCaller caller;
    private final MatchSheetRenderer renderer;

    GetMatchSheetPdf(GetBoxScore boxScores, RosterPort roster, AcademyNames academies, CurrentCaller caller,
            MatchSheetRenderer renderer) {
        this.boxScores = boxScores;
        this.roster = roster;
        this.academies = academies;
        this.caller = caller;
        this.renderer = renderer;
    }

    public PdfFile handle(MatchId matchId, SheetLanguage language) {
        GetBoxScore.BoxScore box = boxScores.handle(matchId);
        TenantId tenant = caller.tenantId();
        String teamName = roster.team(tenant, box.match().teamId()).teamName();
        MatchSheet.Academy academy = MatchSheets.academy(academies.find(tenant), caller.authz().timezone());
        return renderer.render(MatchSheets.of(box, language, academy, teamName));
    }
}
