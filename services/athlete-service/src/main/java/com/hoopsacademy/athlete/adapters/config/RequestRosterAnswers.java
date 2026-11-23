package com.hoopsacademy.athlete.adapters.config;

import jakarta.enterprise.context.RequestScoped;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** The roster answers of the running request ({@link RequestMemoRosterPort}); gone when the request ends. */
@RequestScoped
class RequestRosterAnswers {

    private final Map<RequestMemoRosterPort.TeamKey, RequestMemoRosterPort.Answer> answers = new ConcurrentHashMap<>();

    Map<RequestMemoRosterPort.TeamKey, RequestMemoRosterPort.Answer> answers() {
        return answers;
    }
}
