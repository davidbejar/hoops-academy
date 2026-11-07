package com.hoopsacademy.core.adapters.in.platform;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import java.util.List;

/** Contract {@code AcademyRequestPage}. */
public record AcademyRequestPageDto(List<AcademyRequestDto> items, PageMetaDto page) {}
