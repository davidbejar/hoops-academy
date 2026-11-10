package com.hoopsacademy.core.application.me;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.util.Objects;
import java.util.Optional;

/** PATCH /me: the login's language and, in one academy, the caller's own first and last name (decision 73). */
public record MeChanges(Optional<AppLocale> locale, Optional<OwnName> ownName) {

    public MeChanges {
        Objects.requireNonNull(locale, "locale");
        Objects.requireNonNull(ownName, "ownName");
    }

    /** The caller's own person in {@code tenant}; only the names, never the e-mail (it stays with the admins). */
    public record OwnName(TenantId tenant, Patch<String> givenName, Patch<String> familyName) {

        public OwnName {
            Objects.requireNonNull(tenant, "tenant");
            if (!givenName.isPresent() && !familyName.isPresent()) {
                throw new IllegalArgumentException("an own-name change needs a given or a family name");
            }
        }

        PersonalDataChanges changes() {
            return PersonalDataChanges.none().withGivenName(givenName).withFamilyName(familyName);
        }
    }
}
