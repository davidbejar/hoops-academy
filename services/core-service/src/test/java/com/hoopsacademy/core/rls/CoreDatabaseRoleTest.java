package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.testing.DatabaseRoleMetaTest;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import io.quarkus.test.junit.QuarkusTest;

/** core_app (default datasource) and core_platform (super-admin datasource) are both bound by RLS. */
@QuarkusTest
@CoreTestResources
class CoreDatabaseRoleTest extends DatabaseRoleMetaTest {}
