package com.hoopsacademy.core.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.core.application.export.ExportOrigin;
import com.hoopsacademy.core.application.export.RosterPrint;
import com.hoopsacademy.core.application.export.RosterSheet;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/**
 * WP116: every way pdf-service can fail to render is a 503 {@code UPSTREAM_UNAVAILABLE} whose message (logged by the
 * Problem mapper, never sent) names only the cause and the status, never what was sent.
 */
class PdfServiceRosterPrinterTest {

    private static final byte[] PDF = "%PDF-1.7 sheet".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    private static final RosterPrint ROSTER = new RosterPrint(new RosterSheet(new ExportOrigin("hangtuah",
            ZoneId.of("Asia/Jakarta"), LocalDate.of(2026, 11, 16)), "Secret Lions", List.of(), List.of()),
            "Hang Tuah", "2026/27", "Under 12", AppLocale.EN);

    @Test
    void theSheetIsWhatPdfServiceAnswers() {
        assertThat(new PdfServiceRosterPrinter(Optional.of(request -> PDF)).print(ROSTER)).isEqualTo(PDF);
    }

    @Test
    void withoutAnAddressThePdfIsUnavailable() {
        assertThatThrownBy(() -> new PdfServiceRosterPrinter(Optional.empty()).print(ROSTER))
                .isInstanceOf(UpstreamUnavailableException.class).hasMessageContaining("PDF_SERVICE_URL")
                .extracting("code").isEqualTo("UPSTREAM_UNAVAILABLE");
    }

    @Test
    void anErrorStatusIsUnavailableNamingTheStatusOnly() {
        PdfServiceClient refusing = request -> {
            throw new WebApplicationException("Secret Lions rejected", Response.status(422).build());
        };

        assertThatThrownBy(() -> new PdfServiceRosterPrinter(Optional.of(refusing)).print(ROSTER))
                .isInstanceOf(UpstreamUnavailableException.class).hasMessage("pdf-service answered 422")
                .hasCauseInstanceOf(WebApplicationException.class);
    }

    @Test
    void anUnreachableOrSlowServiceIsUnavailableWithoutTheRequest() {
        PdfServiceClient timingOut = request -> {
            throw new ProcessingException("timeout while sending Secret Lions");
        };

        assertThatThrownBy(() -> new PdfServiceRosterPrinter(Optional.of(timingOut)).print(ROSTER))
                .isInstanceOf(UpstreamUnavailableException.class)
                .hasMessage("pdf-service is not reachable (ProcessingException)");
    }

    @Test
    void anEmptyAnswerIsNotASheet() {
        assertThatThrownBy(() -> new PdfServiceRosterPrinter(Optional.of(request -> new byte[0])).print(ROSTER))
                .isInstanceOf(UpstreamUnavailableException.class).hasMessage("pdf-service answered no sheet");
    }
}
