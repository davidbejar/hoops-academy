package archtest

import (
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// moduleRoot is the directory of go.mod (two levels above this file).
func moduleRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("cannot locate the test file")
	}
	return filepath.Join(filepath.Dir(file), "..", "..")
}

// The counterpart of the Java services' ArchUnit rules (ADR-0055): domain imports nothing but a few standard
// packages, application imports the domain and those packages, nothing inner imports an adapter.
func TestTheServiceRespectsTheHexagonalLayers(t *testing.T) {
	violations, err := Check(moduleRoot(t), Module)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range violations {
		t.Error(v)
	}
}

func TestTheCheckFindsEveryPlantedViolation(t *testing.T) {
	root := filepath.Join(moduleRoot(t), "internal", "archtest", "testdata", "planted")

	violations, err := Check(root, Module)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		"internal/domain/bad.go imports net/http",
		"internal/domain/bad.go imports github.com/jackc/pgx/v5",
		"internal/domain/bad.go imports " + Module + "/internal/application",
		"internal/application/bad.go imports " + Module + "/internal/adapters/out/persistence",
		"internal/application/bad.go imports database/sql",
		"internal/application/bad.go imports " + Module + "/internal/platform",
		"internal/adapters/in/rest/bad.go imports " + Module + "/internal/testsupport/pgtest",
	}
	joined := strings.Join(violations, "\n")
	for _, w := range want {
		if !strings.Contains(joined, w) {
			t.Errorf("planted violation not reported: %q\nreported:\n%s", w, joined)
		}
	}
	if len(violations) != len(want) {
		t.Errorf("reported %d violations, planted %d:\n%s", len(violations), len(want), joined)
	}
}

func TestTheCheckIgnoresTestFilesOnlyForTheTestSupportRule(t *testing.T) {
	root := filepath.Join(moduleRoot(t), "internal", "archtest", "testdata", "planted")

	violations, err := Check(root, Module)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range violations {
		if strings.Contains(v, "_test.go") {
			t.Errorf("a test file may use the test support: %s", v)
		}
	}
}
