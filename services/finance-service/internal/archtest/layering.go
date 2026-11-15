// Package archtest checks the hexagonal layering of the service (ADR-0055), the counterpart of ArchUnit.
package archtest

import "errors"

// Module is the module path of finance-service.
const Module = "hoopsacademy.local/finance"

// Check reports every import that breaks the layering rules under root (a module directory).
func Check(root, module string) ([]string, error) {
	return nil, errors.New("not implemented")
}
