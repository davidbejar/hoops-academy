package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.adapters.in.shared.PageMetaDto;
import java.util.List;

/** Contract {@code MemberPage}. */
public record MemberPageDto(List<MemberDto> items, PageMetaDto page) {}
