package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.shared.Patch;
import java.time.LocalDate;

/** A partial update of a season (merge-patch; no field is clearable). */
public record SeasonChanges(Patch<String> name, Patch<LocalDate> startsOn, Patch<LocalDate> endsOn,
        Patch<Integer> referenceYear) {

    public boolean changesReferenceYear() {
        return referenceYear.isPresent();
    }
}
