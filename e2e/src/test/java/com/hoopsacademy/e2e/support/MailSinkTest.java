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
