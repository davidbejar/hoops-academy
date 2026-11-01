package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.roster.AgeCategory;

/**
 * The verdict plus what it was based on.
 *
 * @param age             age under the tenant's rule, {@code null} without a birth date
 * @param naturalCategory the player's natural category, {@code null} without a birth date or above every category
 */
public record Evaluation(Eligibility eligibility, Integer age, AgeCategory naturalCategory) {}
