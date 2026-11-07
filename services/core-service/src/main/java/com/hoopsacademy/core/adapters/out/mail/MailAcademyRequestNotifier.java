package com.hoopsacademy.core.adapters.out.mail;

import com.hoopsacademy.core.application.port.AcademyRequestNotifier;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.signup.AcademyRequest;
import io.quarkus.mailer.Mail;
import io.quarkus.mailer.Mailer;
import io.quarkus.qute.Engine;
import io.quarkus.qute.TemplateInstance;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Map;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Plain-text decision e-mails (es / en / id, {@code templates/mail}) over SMTP ({@code quarkus.mailer.*} from the
 * environment, ADR-0044). Subjects are constants: no requester input ever reaches a header but the recipient, which the
 * domain has already checked ({@code Requester}). Never the temporary password; no address in the log.
 */
@ApplicationScoped
class MailAcademyRequestNotifier implements AcademyRequestNotifier {

    private static final Logger LOG = Logger.getLogger(MailAcademyRequestNotifier.class);
    private static final Map<AppLocale, String> ACCEPTED_SUBJECT = Map.of(
            AppLocale.EN, "Your academy is ready on Hoops Academy",
            AppLocale.ES, "Tu academia ya está lista en Hoops Academy",
            AppLocale.ID, "Akademimu sudah siap di Hoops Academy");
    private static final Map<AppLocale, String> REJECTED_SUBJECT = Map.of(
            AppLocale.EN, "Your academy request at Hoops Academy",
            AppLocale.ES, "Tu solicitud de academia en Hoops Academy",
            AppLocale.ID, "Permintaan akademimu di Hoops Academy");

    private final Mailer mailer;
    private final Engine templates;
    private final String publicUrl;

    MailAcademyRequestNotifier(Mailer mailer, Engine templates,
            @ConfigProperty(name = "hoops.public-url") String publicUrl) {
        this.mailer = mailer;
        this.templates = templates;
        this.publicUrl = publicUrl.endsWith("/") ? publicUrl.substring(0, publicUrl.length() - 1) : publicUrl;
    }

    @Override
    public boolean accepted(AcademyRequest request, boolean newLogin) {
        return send(request, ACCEPTED_SUBJECT, template("academy-request-accepted", request)
                .data("loginUrl", publicUrl + "/login")
                .data("newLogin", newLogin));
    }

    @Override
    public boolean rejected(AcademyRequest request) {
        return send(request, REJECTED_SUBJECT, template("academy-request-rejected", request)
                .data("reason", request.reason())
                .data("landingUrl", publicUrl + "/"));
    }

    private TemplateInstance template(String name, AcademyRequest request) {
        return templates.getTemplate("mail/" + name + "." + request.requester().locale().code() + ".txt").instance()
                .data("name", request.requester().name().orElse(null))
                .data("email", request.requester().email())
                .data("academyName", request.academyName().value());
    }

    private boolean send(AcademyRequest request, Map<AppLocale, String> subjects, TemplateInstance body) {
        try {
            mailer.send(Mail.withText(request.requester().email(), subjects.get(request.requester().locale()),
                    body.render()));
            return true;
        } catch (RuntimeException e) {
            LOG.warnf("Decision e-mail of academy request %s not sent: %s", request.id(), e.getClass().getSimpleName());
            return false;
        }
    }
}
