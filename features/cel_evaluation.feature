Feature: CEL Expression Evaluation
  In order to evaluate CEL expressions in PostgreSQL
  As a database user
  I need to be able to execute CEL expressions with various data types

  Background:
    Given pg-cel extension is loaded
    And the cache is cleared

  Scenario: Basic CEL expression evaluation
    When I evaluate CEL expression "1 + 2"
    Then the result should be "3"
    And the result type should be "integer"

  Scenario: String concatenation
    When I evaluate CEL expression '"hello" + " " + "world"'
    Then the result should be "hello world"
    And the result type should be "string"

  Scenario: Boolean expression
    When I evaluate CEL expression "true && false"
    Then the result should be "false"
    And the result type should be "boolean"

  Scenario: Math operations
    When I evaluate CEL expression "10 * 5 - 2"
    Then the result should be "48"
    And the result type should be "integer"

  Scenario: Comparison operations
    When I evaluate CEL expression "10 > 5"
    Then the result should be "true"
    And the result type should be "boolean"

  Scenario: List operations
    When I evaluate CEL expression "[1, 2, 3].size()"
    Then the result should be "3"
    And the result type should be "integer"

  Scenario: Type conversion
    When I evaluate CEL expression "string(42) + '_converted'"
    Then the result should be "42_converted"
    And the result type should be "string"

  Scenario Outline: Mathematical operations
    When I evaluate CEL expression "<expression>"
    Then the result should be "<expected>"
    And the result type should be "<type>"

    Examples:
      | expression  | expected | type    |
      | 5 + 3       | 8        | integer |
      | 10 - 4      | 6        | integer |
      | 7 * 6       | 42       | integer |
      | 15 / 3      | 5        | integer |
      | 17 % 5      | 2        | integer |
      | 2.5 + 1.5   | 4        | integer |
