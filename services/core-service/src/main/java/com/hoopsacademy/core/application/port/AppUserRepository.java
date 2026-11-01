package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.identity.UserId;
import java.util.Optional;

/** Platform-wide logins ({@code core.app_user}); always looked up by subject or id, never listed. */
public interface AppUserRepository {

    Optional<AppUser> findBySubject(String subject);

    Optional<AppUser> findById(UserId id);

    /** Returns the login of {@code subject}, registering it on first sight. */
    AppUser findOrRegister(String subject, String email);

    void save(AppUser user);
}
