# BDD Testing with Godog

This directory contains Behavior-Driven Development (BDD) tests for pg-cel using Gherkin syntax and the godog testing framework.

## Overview

The BDD tests cover the following areas:
- **CEL Expression Evaluation**: Basic CEL expression parsing and evaluation
- **JSON Data Processing**: Complex JSON data manipulation with CEL
- **Caching Performance**: Cache behavior and performance validation
- **Error Handling**: Comprehensive error scenarios and validation
- **PostgreSQL Integration**: SQL function integration and database operations

## Test Structure

### Feature Files (`features/`)
- `cel_evaluation.feature` - Basic CEL expression evaluation tests
- `cel_json_evaluation.feature` - JSON data processing with CEL
- `cel_caching.feature` - Cache performance and behavior tests  
- `cel_error_handling.feature` - Error condition validation
- `postgresql_integration.feature` - SQL integration tests

### Step Definitions
- `godog_test.go` - Implementation of all Gherkin step definitions
- `godog_main_test.go` - Test suite configuration and execution

## Running the Tests

### Prerequisites

1. **PostgreSQL Database**: A test database must be available
   ```bash
   createdb test_pgcel
   ```

2. **pg-cel Extension**: The extension must be built and available
   ```bash
   ./build.sh
   sudo make install
   ```

3. **Enable Extension**: Connect to the test database and enable the extension
   ```sql
   CREATE EXTENSION pg_cel;
   ```

### Execute Tests

Run all BDD tests:
```bash
go test -v ./godog_main_test.go ./godog_test.go
```

Run specific features:
```bash
go test -v -godog.tags="@cache" ./godog_main_test.go ./godog_test.go
```

Run with specific format:
```bash
go test -v -godog.format=junit:results.xml ./godog_main_test.go ./godog_test.go
```

### Test Database Configuration

The tests expect a PostgreSQL database with the following connection parameters:
- **Host**: localhost (default)
- **User**: postgres
- **Database**: test_pgcel
- **SSL Mode**: disable

You can modify the connection string in `godog_test.go` if needed:
```go
tc.db, err = sql.Open("postgres", "user=postgres dbname=test_pgcel sslmode=disable")
```

## Test Scenarios

### Basic CEL Evaluation
- Arithmetic operations (`1 + 2`, `10 * 5 - 2`)
- String operations (`"hello" + " world"`)
- Boolean logic (`true && false`)
- Type conversions (`string(42)`)
- List operations (`[1, 2, 3].size()`)

### JSON Data Processing
- Simple property access (`user.name`)
- Nested object navigation (`user.profile.email`)
- Array indexing and operations (`numbers[2]`, `items.size()`)
- Complex filtering (`users.filter(u, u.active && u.age > 30)`)
- Map operations (`scores.map(s, s + 5)`)
- Conditional logic with ternary operators
- Missing property handling with `has()` function

### Caching Performance
- Cache initialization and clearing
- Program cache hit rate validation
- JSON cache performance testing
- Memory limit compliance
- Cache key uniqueness verification
- Cross-session cache persistence

### Error Handling
- Syntax errors in expressions
- Undefined variable references
- Type mismatch errors
- Runtime errors (division by zero, array bounds)
- Invalid JSON parsing
- Null pointer access

### PostgreSQL Integration
- SQL function calls (`cel_eval()`, `cel_eval_bool()`, etc.)
- Integration with table data
- WHERE clause usage
- JSON column processing
- Aggregation functions
- Transaction isolation
- Cache statistics reporting

## Writing New Tests

### Adding New Feature Files

1. Create a new `.feature` file in the `features/` directory
2. Use Gherkin syntax with Given/When/Then steps
3. Follow the existing naming conventions

Example:
```gherkin
Feature: New Functionality
  In order to achieve some goal
  As a user
  I need to be able to do something

  Scenario: Basic test case
    Given some precondition
    When I perform an action
    Then I should see the expected result
```

### Adding New Step Definitions

1. Add step definition functions to `godog_test.go`
2. Use the `InitializeScenario` function to register new steps
3. Follow the context passing pattern for stateful tests

Example:
```go
func (tc *TestContext) iPerformAnAction(ctx context.Context, param string) (context.Context, error) {
    // Implementation
    return ctx, nil
}

// In InitializeScenario:
sc.When(`^I perform an action "([^"]*)"$`, tc.iPerformAnAction)
```

## Test Data

### Database Tables
The tests automatically create and populate test tables:
- `test_users` - User data with name and age
- `test_scores` - Numeric scores for aggregation tests
- `json_table` - JSONB data for complex scenarios

### JSON Test Data
Various JSON structures are used throughout the tests:
- Simple objects (`{"name": "John", "age": 30}`)
- Nested objects (`{"user": {"profile": {"email": "..."}}}`)
- Arrays (`{"numbers": [1, 2, 3, 4, 5]}`)
- Complex structures with filtering and mapping scenarios

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Ensure PostgreSQL is running
   - Verify database exists and is accessible
   - Check connection parameters

2. **Extension Not Found**
   - Build and install pg-cel extension
   - Enable extension in test database
   - Verify installation with `\dx` in psql

3. **Test Failures**
   - Check PostgreSQL logs for errors
   - Verify test database has correct permissions
   - Ensure all dependencies are installed

### Debug Mode

Run tests with verbose output:
```bash
go test -v -godog.format=pretty ./godog_main_test.go ./godog_test.go
```

Add debug logging by modifying step definitions to include additional output.

## Integration with CI/CD

The BDD tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run BDD Tests
  run: |
    createdb test_pgcel
    psql -d test_pgcel -c "CREATE EXTENSION pg_cel;"
    go test -v -godog.format=junit:bdd-results.xml ./godog_main_test.go ./godog_test.go
```

## Best Practices

1. **Isolation**: Each scenario should be independent
2. **Cleanup**: Use hooks to clean up test data
3. **Readability**: Write descriptive scenario names and steps
4. **Coverage**: Aim for comprehensive coverage of functionality
5. **Performance**: Include performance-related scenarios
6. **Error Cases**: Test both happy path and error conditions

## Contributing

When adding new BDD tests:

1. Follow existing patterns and conventions
2. Write clear, descriptive scenarios
3. Include both positive and negative test cases
4. Add appropriate documentation
5. Ensure tests are reproducible and deterministic
6. Test your changes locally before submitting
