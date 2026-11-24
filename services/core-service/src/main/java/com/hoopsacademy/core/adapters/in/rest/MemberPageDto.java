package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.common.paging.PageMeta;
import java.util.List;

/** Contract {@code MemberPage}. */
public record MemberPageDto(List<MemberDto> items, PageMeta page) {}
