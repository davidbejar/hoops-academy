package com.hoopsacademy.core.adapters.out.client;

import com.hoopsacademy.common.client.ServiceTokenClientFilter;
import org.eclipse.microprofile.rest.client.annotation.RegisterProvider;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@RegisterRestClient(configKey = "athlete-usage")
@RegisterProvider(ServiceTokenClientFilter.class)
public interface AthleteUsageClient extends UsageClient {}
