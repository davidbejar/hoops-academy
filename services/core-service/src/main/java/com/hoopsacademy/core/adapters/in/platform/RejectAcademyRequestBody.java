package com.hoopsacademy.core.adapters.in.platform;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Contract {@code RejectAcademyRequest}. */
public record RejectAcademyRequestBody(@NotBlank @Size(max = 500) String reason) {}
