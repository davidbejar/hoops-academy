package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.testing.DatabaseRoleMetaTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;

/** core_app (default datasource) and core_platform (super-admin datasource) are both bound by RLS. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreDatabaseRoleTest extends DatabaseRoleMetaTest {}
