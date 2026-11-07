package com.hoopsacademy.common.problem;

import com.fasterxml.jackson.databind.JsonNode;
import io.agroal.api.AgroalDataSource;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

/** Test-only endpoints that hand request text to PostgreSQL, as the services' searches and writes do (SD-02). */
@Path("/probe/text")
public class TextProbeResource {

    public record TextBody(String name, List<String> tags) {}

    private final AgroalDataSource dataSource;

    public TextProbeResource(AgroalDataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GET
    @Path("/search")
    public String search(@QueryParam("q") String q) {
        return query("select length(cast(? as text))", q);
    }

    @GET
    @Path("/search/{q}")
    public String searchByPath(@PathParam("q") String q) {
        return query("select length(cast(? as text))", q);
    }

    @POST
    @Path("/echo")
    @Consumes(MediaType.APPLICATION_JSON)
    public String echo(TextBody body) {
        return query("select cast(? as text)", body.name());
    }

    @POST
    @Path("/tree")
    @Consumes(MediaType.APPLICATION_JSON)
    public String tree(JsonNode body) {
        return query("select cast(cast(? as jsonb) as text)", body.toString());
    }

    @POST
    @Path("/raw")
    @Consumes(MediaType.TEXT_PLAIN)
    public String raw(String body) {
        return query("select cast(? as text)", body);
    }

    @POST
    @Path("/raw-json")
    @Consumes(MediaType.TEXT_PLAIN)
    public String rawJson(String body) {
        return query("select cast(cast(? as jsonb) as text)", body);
    }

    private String query(String sql, String parameter) {
        try (Connection connection = dataSource.getConnection(); PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, parameter);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getString(1);
            }
        } catch (SQLException e) {
            throw new IllegalStateException("query failed", e);
        }
    }
}
