package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.common.paging.PageMeta;
import java.util.List;

/** Contract {@code AcademyRequestPage}. */
public record AcademyRequestPageDto(List<AcademyRequestDto> items, PageMeta page) {}
