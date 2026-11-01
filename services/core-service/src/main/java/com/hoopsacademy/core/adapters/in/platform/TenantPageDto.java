package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import java.util.List;

/** Contract {@code TenantPage}. */
public record TenantPageDto(List<TenantDto> items, PageMetaDto page) {}
