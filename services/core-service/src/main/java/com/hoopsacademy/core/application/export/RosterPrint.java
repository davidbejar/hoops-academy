package com.hoopsacademy.core.application.export;

import com.hoopsacademy.core.domain.shared.AppLocale;

/**
 * What a printed roster shows (WP116, decision 89): the roster export's content and the heading of the sheet (the
 * academy's name, the team's season and age category), with labels in {@code language}.
 */
public record RosterPrint(RosterSheet sheet, String academyName, String seasonName, String categoryName,
        AppLocale language) {}
