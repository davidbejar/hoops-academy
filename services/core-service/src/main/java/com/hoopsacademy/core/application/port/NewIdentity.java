package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.shared.AppLocale;

/** A login to provision in the identity provider. */
public record NewIdentity(String email, String givenName, String familyName, AppLocale locale) {}
