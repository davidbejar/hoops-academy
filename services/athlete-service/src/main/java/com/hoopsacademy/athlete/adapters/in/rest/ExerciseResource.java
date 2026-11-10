package com.hoopsacademy.athlete.adapters.in.rest;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.ExerciseRepository;
import com.hoopsacademy.athlete.application.InvalidRequestException;
import com.hoopsacademy.athlete.application.ManageExercises;
import com.hoopsacademy.athlete.domain.ExerciseId;
import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Arrays;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** The exercise catalogue (athlete 3.0.0, decision 72, ADR-0047). */
@Path("/api/athlete/exercises")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER})
public class ExerciseResource {

    /** The clear enum of UpdateExerciseRequest in athlete.yaml (ADR-0032). */
    private static final Set<String> CLEARABLE = Set.of("description", "durationMinutes", "sets", "repetitions", "videoUrl");
    private static final int MAX_QUERY = 100;
    private static final String ACCEPT_LANGUAGE = "Accept-Language";

    private final ManageExercises exercises;
    private final TenantContext tenant;

    ExerciseResource(ManageExercises exercises, TenantContext tenant) {
        this.exercises = exercises;
        this.tenant = tenant;
    }

    @GET
    public PageDto<ExerciseDtos.Exercise> list(@QueryParam("q") String q, @QueryParam("scope") String scope,
            @QueryParam("includeArchived") String includeArchived,
            @QueryParam("page") @DefaultValue("0") @Min(0) int page,
            @QueryParam("size") @DefaultValue("50") @Min(1) @Max(200) int size,
            @HeaderParam(ACCEPT_LANGUAGE) String acceptLanguage) {
        Optional<String> query = Optional.ofNullable(q).filter(text -> !text.isBlank());
        if (query.filter(text -> text.length() > MAX_QUERY).isPresent()) {
            throw new InvalidRequestException("q", "INVALID_VALUE", "q must be at most 100 characters");
        }
        var search = new ExerciseRepository.Search(scope(scope),
                Requests.bool("includeArchived", includeArchived, false), query,
                AcceptLanguage.negotiate(acceptLanguage), page, size);
        return PageDto.of(exercises.list(search), ExerciseDtos.Exercise::from);
    }

    @POST
    public Response create(@Valid @NotNull ExerciseDtos.Input request) {
        var created = exercises.create(caller(), request.fields());
        return Response.status(Response.Status.CREATED).entity(ExerciseDtos.Exercise.from(created)).build();
    }

    @GET
    @Path("/{exerciseId}")
    public ExerciseDtos.Exercise get(@PathParam("exerciseId") UUID exerciseId,
            @HeaderParam(ACCEPT_LANGUAGE) String acceptLanguage) {
        return ExerciseDtos.Exercise.from(exercises.get(new ExerciseId(exerciseId), AcceptLanguage.negotiate(acceptLanguage)));
    }

    @PATCH
    @Path("/{exerciseId}")
    public ExerciseDtos.Exercise update(@PathParam("exerciseId") UUID exerciseId, JsonNode body) {
        PatchBody patch = new PatchBody(body, CLEARABLE);
        var change = new ManageExercises.ExerciseChange(
                patch.required("title", PatchBody.nonBlankText(120)),
                patch.nullable("description", PatchBody.text(4000)),
                patch.nullable("durationMinutes", PatchBody.integer(1, 480)),
                patch.nullable("sets", PatchBody.integer(1, 100)),
                patch.nullable("repetitions", PatchBody.integer(1, 1000)),
                patch.nullable("videoUrl", PatchBody.text(2000)));
        return ExerciseDtos.Exercise.from(exercises.update(caller(), new ExerciseId(exerciseId), change));
    }

    /** Custom methods like {@code :archive}; clients send the colon unencoded (libs/contracts README). */
    @POST
    @Path("/{exerciseId}:archive")
    public ExerciseDtos.Exercise archive(@PathParam("exerciseId") UUID exerciseId) {
        return ExerciseDtos.Exercise.from(exercises.setArchived(caller(), new ExerciseId(exerciseId), true));
    }

    @POST
    @Path("/{exerciseId}:unarchive")
    public ExerciseDtos.Exercise unarchive(@PathParam("exerciseId") UUID exerciseId) {
        return ExerciseDtos.Exercise.from(exercises.setArchived(caller(), new ExerciseId(exerciseId), false));
    }

    private static Optional<ExerciseRepository.Scope> scope(String raw) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        return Optional.of(Arrays.stream(ExerciseRepository.Scope.values()).filter(s -> s.name().equals(raw)).findFirst()
                .orElseThrow(() -> new InvalidRequestException("scope", "INVALID_VALUE", "scope must be GLOBAL or TENANT")));
    }

    private AuthzContext caller() {
        return tenant.requireAuthz();
    }
}
