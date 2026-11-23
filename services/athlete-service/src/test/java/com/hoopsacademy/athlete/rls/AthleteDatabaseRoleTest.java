package com.hoopsacademy.athlete.rls;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.DatabaseRoleMetaTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class AthleteDatabaseRoleTest extends DatabaseRoleMetaTest {}
