package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.core.adapters.in.shared.Constraints;
import com.hoopsacademy.core.adapters.in.shared.MergePatch;
import com.hoopsacademy.core.application.roster.AgeCategoryService;
import com.hoopsacademy.core.application.roster.AgeCategoryService.NewAgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryChanges;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.List;
import java.util.UUID;

/** The tenant's age categories (any member reads; ADMIN writes). */
@Path("/api/core/age-categories")
@Produces(MediaType.APPLICATION_JSON)
public class AgeCategoryResource {

    private static final java.util.regex.Pattern CODE = java.util.regex.Pattern.compile(Constraints.CATEGORY_CODE);

    /** Contract {@code AgeCategoryInput}. */
    public record AgeCategoryInput(@NotNull @Pattern(regexp = Constraints.CATEGORY_CODE) String code,
            @NotNull @Size(min = 1, max = 60) String name, @Min(AgeCategory.MIN_AGE) @Max(AgeCategory.MAX_AGE) Integer maxAge,
            @NotNull @Min(0) Integer rank) {}

    private final AgeCategoryService categories;

    public AgeCategoryResource(AgeCategoryService categories) {
        this.categories = categories;
    }

    @GET
    public List<AgeCategoryDto> list() {
        return categories.list().stream().map(AgeCategoryDto::of).toList();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid @NotNull AgeCategoryInput input, UriInfo uri) {
        AgeCategoryDto created = AgeCategoryDto.of(categories.create(
                new NewAgeCategory(input.code(), input.name(), input.maxAge(), input.rank())));
        return Response.created(uri.getAbsolutePathBuilder().path(created.id().toString()).build()).entity(created).build();
    }

    @PATCH
    @Path("/{ageCategoryId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public AgeCategoryDto update(@PathParam("ageCategoryId") UUID id, @NotNull JsonNode body) {
        MergePatch patch = MergePatch.of(body);
        AgeCategoryChanges changes = new AgeCategoryChanges(
                patch.matching("code", false, CODE),
                patch.requiredText("name", 60),
                patch.integer("maxAge", true, AgeCategory.MIN_AGE, AgeCategory.MAX_AGE),
                patch.integer("rank", false, 0, Integer.MAX_VALUE));
        patch.validate(true);
        return AgeCategoryDto.of(categories.update(new AgeCategoryId(id), changes));
    }

    @DELETE
    @Path("/{ageCategoryId}")
    public void delete(@PathParam("ageCategoryId") UUID id) {
        categories.delete(new AgeCategoryId(id));
    }
}
