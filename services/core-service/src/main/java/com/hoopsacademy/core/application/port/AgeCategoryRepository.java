package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import java.util.List;
import java.util.Optional;

/** Age categories of the bound tenant. */
public interface AgeCategoryRepository {

    void insert(AgeCategory category);

    void update(AgeCategory category);

    void delete(AgeCategoryId id);

    Optional<AgeCategory> find(AgeCategoryId id);

    List<AgeCategory> listByRank();
}
