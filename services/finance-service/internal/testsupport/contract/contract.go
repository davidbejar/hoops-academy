// Package contract validates the requests tests send and the responses the service answers against
// libs/contracts/openapi/finance.yaml (and common.yaml), the counterpart of the Java services' OpenApiValidationFilter:
// a response with an undeclared status, media type or shape fails the test.
package contract

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"path/filepath"
	"sync"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers"
	"github.com/getkin/kin-openapi/routers/gorillamux"

	"hoopsacademy.local/finance/internal/testsupport/pgtest"
)

// Path is finance.yaml.
func Path() string {
	return filepath.Join(pgtest.RepoRoot(), "libs", "contracts", "openapi", "finance.yaml")
}

var (
	once      sync.Once
	document  *openapi3.T
	router    routers.Router
	loadError error
)

// Document is the parsed and validated contract.
func Document(t testing.TB) (*openapi3.T, routers.Router) {
	t.Helper()
	once.Do(func() {
		loader := openapi3.NewLoader()
		loader.IsExternalRefsAllowed = true
		document, loadError = loader.LoadFromFile(Path())
		if loadError == nil {
			loadError = document.Validate(context.Background())
		}
		if loadError == nil {
			router, loadError = gorillamux.NewRouter(document)
		}
	})
	if loadError != nil {
		t.Fatalf("finance.yaml: %v", loadError)
	}
	return document, router
}

var options = &openapi3filter.Options{
	AuthenticationFunc: openapi3filter.NoopAuthenticationFunc,
	MultiError:         true,
}

// Exchange is one request and its answer, with the bodies kept.
type Exchange struct {
	Request      *http.Request
	RequestBody  []byte
	Response     *http.Response
	ResponseBody []byte
}

// CheckRequest fails the test when request (a request the test expects the service to accept) breaks the contract.
func CheckRequest(t testing.TB, e Exchange) {
	t.Helper()
	input := requestInput(t, e)
	if input == nil {
		return
	}
	if err := openapi3filter.ValidateRequest(context.Background(), input); err != nil {
		t.Errorf("%s %s: the request breaks finance.yaml: %v", e.Request.Method, e.Request.URL.Path, err)
	}
}

// CheckResponse fails the test when the answer breaks the contract.
func CheckResponse(t testing.TB, e Exchange) {
	t.Helper()
	input := requestInput(t, e)
	if input == nil {
		return
	}
	err := openapi3filter.ValidateResponse(context.Background(), &openapi3filter.ResponseValidationInput{
		RequestValidationInput: input, Status: e.Response.StatusCode, Header: e.Response.Header,
		Body: io.NopCloser(bytes.NewReader(e.ResponseBody)), Options: options,
	})
	if err != nil {
		t.Errorf("%s %s -> %d: the response breaks finance.yaml: %v\nbody: %s", e.Request.Method, e.Request.URL.Path,
			e.Response.StatusCode, err, e.ResponseBody)
	}
}

func requestInput(t testing.TB, e Exchange) *openapi3filter.RequestValidationInput {
	t.Helper()
	_, r := Document(t)
	request := e.Request.Clone(context.Background())
	request.Body = io.NopCloser(bytes.NewReader(e.RequestBody))
	route, params, err := r.FindRoute(request)
	if err != nil {
		t.Errorf("%s %s is not an operation of finance.yaml: %v", e.Request.Method, e.Request.URL.Path, err)
		return nil
	}
	return &openapi3filter.RequestValidationInput{Request: request, PathParams: params, Route: route, Options: options}
}
