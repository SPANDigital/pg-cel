package godog_test

import (
	"os"
	"testing"

	"github.com/cucumber/godog"
	"github.com/cucumber/godog/colors"
)

// TestFeatures runs the godog BDD tests
func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		TestSuiteInitializer: InitializeTestSuite,
		ScenarioInitializer:  InitializeScenario,
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"features"},
			TestingT: t,
			Output:   colors.Colored(os.Stdout),
		},
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}

// TestSuiteInitializer initializes the test suite
func InitializeTestSuite(ctx *godog.TestSuiteContext) {
	ctx.BeforeSuite(func() {
		// Suite-level setup
		// Could initialize database connections, test data, etc.
	})

	ctx.AfterSuite(func() {
		// Suite-level cleanup
		// Could clean up test database, temporary files, etc.
	})
}
