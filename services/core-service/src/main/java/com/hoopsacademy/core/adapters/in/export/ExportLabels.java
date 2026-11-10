package com.hoopsacademy.core.adapters.in.export;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.audit.AuditActorKind;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditTargetType;
import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.shared.AppLocale;
import java.text.MessageFormat;
import java.util.Locale;
import java.util.ResourceBundle;
import java.util.Set;

/**
 * Header and enum labels of the server-built exports in es / en / id ({@code i18n/export_<code>.properties},
 * ADR-0048). Values other than enum labels are never translated.
 */
public final class ExportLabels {

    private static final String BUNDLE = "i18n.export";

    private final ResourceBundle bundle;
    private final Locale locale;

    private ExportLabels(ResourceBundle bundle, Locale locale) {
        this.bundle = bundle;
        this.locale = locale;
    }

    public static ExportLabels of(AppLocale language) {
        Locale locale = Locale.of(language.code());
        return new ExportLabels(ResourceBundle.getBundle(BUNDLE, locale,
                ResourceBundle.Control.getNoFallbackControl(ResourceBundle.Control.FORMAT_PROPERTIES)), locale);
    }

    /** The label of {@code key}, its {@code {0}}… placeholders filled with {@code arguments}. */
    public String text(String key, Object... arguments) {
        String pattern = bundle.getString(key);
        return arguments.length == 0 ? pattern : new MessageFormat(pattern, locale).format(arguments);
    }

    public Set<String> keys() {
        return bundle.keySet();
    }

    public String role(TenantRole role) {
        return text("role." + role.name());
    }

    /** {@code null} for a missing gender. */
    public String gender(Gender gender) {
        return gender == null ? null : text("gender." + gender.name());
    }

    public String action(AuditAction action) {
        return text("action." + action.wireName());
    }

    public String actor(AuditActorKind kind) {
        return text("actor." + kind.name());
    }

    public String target(AuditTargetType type) {
        return text("target." + type.wireName());
    }
}
