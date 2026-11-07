package com.hoopsacademy.e2e.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/** The mail support class against fake MailHog (API v2) and Mailpit (API v1) servers. */
class MailSinkTest {

    private static final String MAILHOG_LIST = """
            {"total":1,"count":1,"start":0,"items":[{"ID":"a","To":[{"Relays":null,"Mailbox":"Coach.One","Domain":"example.org","Params":""}]}]}
            """;
    private static final String MAILPIT_LIST = """
            {"total":1,"count":1,"messages":[{"ID":"a","To":[{"Name":"","Address":"coach.one@example.org"}]}]}
            """;

    private HttpServer server;

    @AfterEach
    void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    private String serve(Map<String, String> bodiesByPath) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", ex -> {
            String body = bodiesByPath.get(ex.getRequestURI().getPath());
            byte[] out = (body == null ? "not found" : body).getBytes(StandardCharsets.UTF_8);
            ex.getResponseHeaders().add("Content-Type", "application/json");
            ex.sendResponseHeaders(body == null ? 404 : 200, out.length);
            ex.getResponseBody().write(out);
            ex.close();
        });
        server.start();
        return "http://127.0.0.1:" + server.getAddress().getPort();
    }

    @Test
    void readsMailHogApiV2() throws IOException {
        MailSink sink = new MailSink(serve(Map.of("/api/v2/messages", MAILHOG_LIST)));

        assertThat(sink.reachable()).isTrue();
        assertThat(sink.hasMessageTo("coach.one@example.org")).isTrue();
        assertThat(sink.hasMessageTo("someone.else@example.org")).isFalse();
    }

    @Test
    void readsMailpitApiV1WhenV2Answers404() throws IOException {
        MailSink sink = new MailSink(serve(Map.of("/api/v1/messages", MAILPIT_LIST)));

        assertThat(sink.reachable()).isTrue();
        assertThat(sink.hasMessageTo("COACH.ONE@example.org")).isTrue();
        assertThat(sink.hasMessageTo("someone.else@example.org")).isFalse();
    }

    @Test
    void readsTheNewestTextToARecipientFromMailHogDecodingQuotedPrintable() throws IOException {
        String list = """
                {"total":2,"count":2,"start":0,"items":[
                 {"ID":"b","To":[{"Mailbox":"ana","Domain":"example.org"}],
                  "Content":{"Body":"Your academy =C3=A9 is ready.=\\r\\nSign in at http://x/login\\r\\n"}},
                 {"ID":"a","To":[{"Mailbox":"ana","Domain":"example.org"}],"Content":{"Body":"older"}}]}
                """;
        MailSink sink = new MailSink(serve(Map.of("/api/v2/messages", list)));

        assertThat(sink.textTo("ANA@example.org")).isEqualTo("Your academy \u00e9 is ready.Sign in at http://x/login\r\n");
        assertThat(sink.textTo("bob@example.org")).isNull();
    }

    @Test
    void readsTheTextOfAMailpitMessage() throws IOException {
        MailSink sink = new MailSink(serve(Map.of("/api/v1/messages", MAILPIT_LIST,
                "/api/v1/message/a", "{\"ID\":\"a\",\"Text\":\"Hola =\"}")));

        assertThat(sink.textTo("coach.one@example.org")).isEqualTo("Hola =");
    }

    @Test
    void isNotReachableWhenNothingListens() throws IOException {
        String url = serve(Map.of());
        server.stop(0);
        server = null;

        assertThat(new MailSink(url).reachable()).isFalse();
    }

    @Test
    void isNotReachableWhenNeitherApiAnswers() throws IOException {
        assertThat(new MailSink(serve(Map.of("/other", "{}"))).reachable()).isFalse();
    }
}
