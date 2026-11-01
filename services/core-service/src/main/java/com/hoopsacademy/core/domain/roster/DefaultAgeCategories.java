package com.hoopsacademy.core.domain.roster;

import java.util.List;

/** The ladder every new academy starts with (plan §2): U8 (≤ 7) … U18 (≤ 17), SENIOR (no limit). */
public final class DefaultAgeCategories {

    private DefaultAgeCategories() {}

    public static List<AgeCategory> create() {
        return List.of(
                category("U8", "U8", 7, 0),
                category("U10", "U10", 9, 1),
                category("U12", "U12", 11, 2),
                category("U14", "U14", 13, 3),
                category("U16", "U16", 15, 4),
                category("U18", "U18", 17, 5),
                category("SENIOR", "Senior", null, 6));
    }

    private static AgeCategory category(String code, String name, Integer maxAge, int rank) {
        return new AgeCategory(AgeCategoryId.random(), code, name, maxAge, rank);
    }
}
