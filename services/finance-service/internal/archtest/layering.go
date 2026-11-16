// Package archtest checks the hexagonal layering of the service (ADR-0055), the counterpart of the Java services'
// ArchUnit rules:
//   - internal/domain imports only the standard packages of domainStd (no framework, no I/O) and itself;
//   - internal/application imports the domain, itself and the standard packages of applicationStd;
//   - nothing but a _test.go file (or the test support itself) imports internal/testsupport;
//   - adapters, platform and cmd may import anything else.
package archtest

import (
	"fmt"
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
)

// Module is the module path of finance-service.
const Module = "hoopsacademy.local/finance"

var domainStd = []string{
	"bytes", "cmp", "errors", "fmt", "maps", "math", "regexp", "slices", "sort", "strconv", "strings", "time",
	"unicode", "unicode/utf8",
}

// applicationStd adds context (cancellation and deadlines cross the ports) to the domain's list; logging, security
// events and audit records leave the application through ports.
var applicationStd = append(slices.Clone(domainStd), "context")

type layer int

const (
	outer layer = iota
	domain
	application
)

func layerOf(rel string) layer {
	switch {
	case strings.HasPrefix(rel, "internal/domain/") || rel == "internal/domain":
		return domain
	case strings.HasPrefix(rel, "internal/application/") || rel == "internal/application":
		return application
	default:
		return outer
	}
}

// Check reports every import that breaks the layering rules in the Go files under root (a module directory), as
// "<file relative to root> imports <path>". testdata directories are skipped, as the go tool skips them.
func Check(root, module string) ([]string, error) {
	var violations []string
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if entry.Name() == "testdata" && path != root {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") {
			return nil
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return fmt.Errorf("relative path of %s: %w", path, err)
		}
		found, err := checkFile(path, filepath.ToSlash(rel), module)
		violations = append(violations, found...)
		return err
	})
	if err != nil {
		return nil, fmt.Errorf("layering check: %w", err)
	}
	return violations, nil
}

func checkFile(path, rel, module string) ([]string, error) {
	file, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
	if err != nil {
		return nil, fmt.Errorf("parse %s: %w", rel, err)
	}
	isTest := strings.HasSuffix(rel, "_test.go")
	var violations []string
	for _, spec := range file.Imports {
		imported, err := strconv.Unquote(spec.Path.Value)
		if err != nil {
			return nil, fmt.Errorf("import path in %s: %w", rel, err)
		}
		support := strings.HasPrefix(rel, "internal/testsupport/") // test support builds on test support
		if !allowed(layerOf(filepath.Dir(rel)+"/"), imported, module, isTest || support) {
			violations = append(violations, rel+" imports "+imported)
		}
	}
	return violations, nil
}

func allowed(from layer, imported, module string, isTest bool) bool {
	inner := strings.TrimPrefix(imported, module+"/")
	own := inner != imported
	if own && strings.HasPrefix(inner, "internal/testsupport") {
		return isTest
	}
	if isTest {
		return true // tests of a layer may use anything (fakes, assertions); the rule is about the production code
	}
	switch from {
	case domain:
		return own && layerOf(inner+"/") == domain || slices.Contains(domainStd, imported)
	case application:
		return own && layerOf(inner+"/") != outer || slices.Contains(applicationStd, imported)
	default:
		return true
	}
}
