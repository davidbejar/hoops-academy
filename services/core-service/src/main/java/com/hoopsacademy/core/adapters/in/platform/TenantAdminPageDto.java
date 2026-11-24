package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.common.paging.PageMeta;
import java.util.List;

/** Contract {@code TenantAdminPage}. */
public record TenantAdminPageDto(List<TenantAdminDto> items, PageMeta page) {}
