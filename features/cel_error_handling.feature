Feature: CEL Error Handling
  In order to handle invalid CEL expressions gracefully
  As a database user
  I need to receive meaningful error messages for invalid expressions

  Background:
    Given pg-cel extension is loaded

  Scenario: Syntax error in expression
    When I evaluate invalid CEL expression "1 +"
    Then I should receive a compilation error
    And the error message should contain "syntax error"

  Scenario: Undefined variable
    When I evaluate CEL expression "undefined_variable"
    Then I should receive a compilation error
    And the error message should contain "undeclared reference"

  Scenario: Type mismatch
    When I evaluate CEL expression "1 + 'string'"
    Then I should receive a compilation error
    And the error message should contain "type"

  Scenario: Division by zero
    When I evaluate CEL expression "10 / 0"
    Then I should receive a runtime error
    And the error message should contain "division by zero"

  Scenario: Invalid JSON data
    Given I have invalid JSON data:
      """
      {"incomplete": 
      """
    When I evaluate CEL expression "incomplete"
    Then I should receive a JSON parsing error
    And the error message should contain "JSON"

  Scenario: Array index out of bounds
    Given I have JSON data:
      """
      {"numbers": [1, 2, 3]}
      """
    When I evaluate CEL expression "numbers[10]"
    Then I should receive a runtime error
    And the error message should contain "index"

  Scenario: Invalid function call
    When I evaluate CEL expression "unknown_function()"
    Then I should receive a compilation error
    And the error message should contain "undeclared reference"

  Scenario: Null pointer access
    Given I have JSON data:
      """
      {"value": null}
      """
    When I evaluate CEL expression "value.property"
    Then I should receive a runtime error
    And the error message should contain "null"

  Scenario Outline: Various error conditions
    When I evaluate invalid CEL expression "<expression>"
    Then I should receive an error
    And the error type should be "<error_type>"

    Examples:
      | expression           | error_type  |
      | 1 +                 | compilation |
      | unknown_var         | compilation |
      | 1 / 0               | runtime     |
      | [1,2,3][5]         | runtime     |
      | null.field         | runtime     |
      | 1 + "string"       | compilation |
