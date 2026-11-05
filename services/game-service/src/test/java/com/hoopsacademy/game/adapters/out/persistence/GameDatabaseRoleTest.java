package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.common.testing.DatabaseRoleMetaTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.support.CoreWireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class GameDatabaseRoleTest extends DatabaseRoleMetaTest {}
