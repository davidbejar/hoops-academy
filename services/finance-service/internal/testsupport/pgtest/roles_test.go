package pgtest

import (
	"reflect"
	"strings"
	"testing"
)

// The harness takes the bootstrap roles from the one list in infra/db/init/01_roles_schemas.sql (INF-03).
func TestBootstrapRolesAreTheListOfTheSQL(t *testing.T) {
	roles, err := BootstrapRoles()
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"core_migrator", "core_app", "core_platform", "game_migrator", "game_app", "athlete_migrator",
		"athlete_app", "finance_migrator", "finance_app"}
	if !reflect.DeepEqual(roles, want) {
		t.Fatalf("roles = %v, want %v", roles, want)
	}
}

func TestASQLWithoutTheListIsAnError(t *testing.T) {
	if _, err := rolesOf("create role x;\n"); err == nil || !strings.Contains(err.Error(), "roles: begin") {
		t.Fatalf("err = %v", err)
	}
}
