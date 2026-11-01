package com.hoopsacademy.archfixture.nativesql.adapters.out.persistence;

import java.sql.Connection;
import java.sql.SQLException;

public class JdbcHelper {

    public void run(Connection connection) throws SQLException {
        connection.prepareStatement("select 1").execute();
    }
}
