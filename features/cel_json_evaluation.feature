Feature: CEL JSON Data Evaluation
  In order to evaluate CEL expressions with complex data
  As a database user
  I need to be able to use JSON data in CEL expressions

  Background:
    Given pg-cel extension is loaded
    And the cache is cleared

  Scenario: Simple JSON variable access
    Given I have JSON data:
      """
      {"name": "John", "age": 30}
      """
    When I evaluate CEL expression "name"
    Then the result should be "John"
    And the result type should be "string"

  Scenario: Nested JSON access
    Given I have JSON data:
      """
      {"user": {"name": "Alice", "profile": {"email": "alice@example.com"}}}
      """
    When I evaluate CEL expression "user.profile.email"
    Then the result should be "alice@example.com"
    And the result type should be "string"

  Scenario: JSON array access
    Given I have JSON data:
      """
      {"numbers": [1, 2, 3, 4, 5]}
      """
    When I evaluate CEL expression "numbers[2]"
    Then the result should be "3"
    And the result type should be "integer"

  Scenario: JSON array operations
    Given I have JSON data:
      """
      {"items": ["apple", "banana", "cherry"]}
      """
    When I evaluate CEL expression "items.size()"
    Then the result should be "3"
    And the result type should be "integer"

  Scenario: Complex JSON filtering
    Given I have JSON data:
      """
      {"users": [
        {"name": "John", "age": 25, "active": true},
        {"name": "Jane", "age": 30, "active": false},
        {"name": "Bob", "age": 35, "active": true}
      ]}
      """
    When I evaluate CEL expression "users.filter(u, u.active && u.age > 30).size()"
    Then the result should be "1"
    And the result type should be "integer"

  Scenario: JSON map operations
    Given I have JSON data:
      """
      {"scores": [85, 92, 78, 96, 89]}
      """
    When I evaluate CEL expression "scores.filter(s, s > 90).size()"
    Then the result should be "2"
    And the result type should be "integer"

  Scenario: JSON conditional logic
    Given I have JSON data:
      """
      {"user": {"role": "admin", "permissions": ["read", "write", "delete"]}}
      """
    When I evaluate CEL expression 'user.role == "admin" ? "full_access" : "limited_access"'
    Then the result should be "full_access"
    And the result type should be "string"

  Scenario: Missing JSON property handling
    Given I have JSON data:
      """
      {"name": "Test", "profile": {"email": "test@example.com"}}
      """
    When I evaluate CEL expression "has(profile.missing_field) ? profile.missing_field : 'default'"
    Then the result should be "default"
    And the result type should be "string"

  Scenario Outline: JSON data type validation
    Given I have JSON data:
      """
      {"value": <json_value>}
      """
    When I evaluate CEL expression "type(value)"
    Then the result should be "<expected_type>"

    Examples:
      | json_value | expected_type |
      | "hello"    | string        |
      | 42         | double        |
      | 3.14       | double        |
      | true       | bool          |
      | null       | null_type     |
      | []         | list(dyn)     |
      | {}         | map(dyn, dyn) |
