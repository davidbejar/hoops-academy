package com.hoopsacademy.core.config;

import com.hoopsacademy.common.testing.NoBuiltInCredentialsContract;
import java.util.Set;

/** core-service's shipped credentials come from the environment only (it lacked the check until WP137, X-10). */
class NoBuiltInCredentialsTest extends NoBuiltInCredentialsContract {

    /**
     * ADR-0044 §9: the decision e-mails go to compose's MailHog by default, which takes no login, so the SMTP password
     * may be empty; a real server gets SMTP_PASSWORD from the environment (docs/wp/FOLLOW-UPS.md, mail).
     */
    @Override
    protected Set<String> exemptions() {
        return Set.of("quarkus.mailer.password");
    }
}
