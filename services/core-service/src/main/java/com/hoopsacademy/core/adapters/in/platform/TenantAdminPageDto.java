package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import java.util.List;

/** Contract {@code TenantAdminPage}. */
public record TenantAdminPageDto(List<TenantAdminDto> items, PageMetaDto page) {}
