package com.hoopsacademy.core.adapters.in.platform;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Contract {@code TenantLifecycleRequest}. */
public record TenantLifecycleRequest(@NotBlank @Size(max = 500) String reason) {}
