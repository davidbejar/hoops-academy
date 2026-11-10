package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.core.application.port.PlatformUsers;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/**
 * GET /platform/users (super_admin, decision 71): read-only; e-mail changes and temporary passwords stay with the
 * per-academy operations. Not recorded in the audit trail, which records administrative changes only (ADR-0029); the
 * search text may be an e-mail, so it is never logged.
 */
@ApplicationScoped
public class ListPlatformUsers {

    private final PlatformUsers users;

    public ListPlatformUsers(PlatformUsers users) {
        this.users = users;
    }

    @Transactional
    public PageResult<PlatformUsers.Login> list(Optional<String> query, PageRequest page) {
        return users.list(query, page);
    }
}
