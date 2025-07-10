Feature: Advanced CEL Features
  In order to leverage advanced CEL capabilities
  As a database user
  I need to be able to use complex CEL expressions and extensions

  Background:
    Given pg-cel extension is loaded
    And the cache is cleared

  @advanced
  Scenario: String manipulation functions
    When I evaluate CEL expression 'size("hello world")'
    Then the result should be "11"
    And the result type should be "integer"

  @advanced
  Scenario: Regular expression matching
    When I evaluate CEL expression '"hello@example.com".matches(".*@.*\\.com")'
    Then the result should be "true"
    And the result type should be "boolean"

  @advanced
  Scenario: String contains and starts/ends with
    When I evaluate CEL expression '"hello world".contains("world")'
    Then the result should be "true"
    And the result type should be "boolean"

  @advanced
  Scenario: Timestamp operations
    Given I have JSON data:
      """
      {"timestamp": "2023-01-01T12:00:00Z"}
      """
    When I evaluate CEL expression 'timestamp(timestamp).getFullYear()'
    Then the result should be "2023"
    And the result type should be "integer"

  @advanced
  Scenario: Duration calculations
    When I evaluate CEL expression 'duration("1h") + duration("30m")'
    Then the result should be "5400s"
    And the result type should be "duration"

  @advanced
  Scenario: Complex list operations with filtering
    Given I have JSON data:
      """
      {"numbers": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}
      """
    When I evaluate CEL expression 'numbers.filter(n, n % 2 == 0)'
    Then the result should be "[2, 4, 6, 8, 10]"
    And the result type should be "list"

  @advanced
  Scenario: List transformation with filtering
    Given I have JSON data:
      """
      {"names": ["alice", "bob", "charlie"]}
      """
    When I evaluate CEL expression 'names.filter(n, n.size() > 3).size()'
    Then the result should be "3"
    And the result type should be "integer"

  @advanced
  Scenario: Complex nested object evaluation
    Given I have JSON data:
      """
      {
        "users": [
          {
            "name": "Alice",
            "profile": {
              "age": 30,
              "preferences": {"theme": "dark", "notifications": true}
            },
            "roles": ["admin", "user"]
          },
          {
            "name": "Bob", 
            "profile": {
              "age": 25,
              "preferences": {"theme": "light", "notifications": false}
            },
            "roles": ["user"]
          }
        ]
      }
      """
    When I evaluate CEL expression 'users.filter(u, "admin" in u.roles && u.profile.age >= 30)[0].name'
    Then the result should be "Alice"
    And the result type should be "string"

  @advanced
  Scenario: Mathematical functions
    When I evaluate CEL expression 'math.ceil(3.14)'
    Then the result should be "4"
    And the result type should be "integer"

  @advanced
  Scenario: Type checking and conversion
    Given I have JSON data:
      """
      {"value": 42}
      """
    When I evaluate CEL expression 'type(value) == int && string(value)'
    Then the result should be "42"
    And the result type should be "string"

  @advanced
  Scenario: Conditional expressions with complex logic
    Given I have JSON data:
      """
      {
        "user": {
          "role": "admin",
          "permissions": ["read", "write", "delete"],
          "active": true,
          "last_login": "2023-12-01T10:00:00Z"
        }
      }
      """
    When I evaluate CEL expression 'user.active && "admin" == user.role && size(user.permissions) >= 3 ? "full_access" : "restricted"'
    Then the result should be "full_access"
    And the result type should be "string"

  @advanced
  Scenario: Null handling and optional chaining
    Given I have JSON data:
      """
      {
        "user": {
          "name": "John",
          "profile": null
        }
      }
      """
    When I evaluate CEL expression 'user.profile == null ? "no_profile" : user.profile.email'
    Then the result should be "no_profile"
    And the result type should be "string"

  @advanced
  Scenario: Set operations with lists
    Given I have JSON data:
      """
      {
        "list1": [1, 2, 3, 4],
        "list2": [3, 4, 5, 6]
      }
      """
    When I evaluate CEL expression 'list1.filter(x, x in list2)'
    Then the result should be "[3, 4]"
    And the result type should be "list"

  @advanced
  Scenario: String formatting and interpolation
    Given I have JSON data:
      """
      {"name": "Alice", "age": 30}
      """
    When I evaluate CEL expression '"Hello, " + name + "! You are " + string(age) + " years old."'
    Then the result should be "Hello, Alice! You are 30 years old."
    And the result type should be "string"

  @advanced
  Scenario Outline: Advanced mathematical operations
    When I evaluate CEL expression "<expression>"
    Then the result should be "<expected>"
    And the result type should be "<type>"

    Examples:
      | expression             | expected | type    |
      | math.abs(-42)         | 42       | integer |
      | math.greatest([1,5,3]) | 5        | integer |
      | math.least([1,5,3])   | 1        | integer |
      | size("unicode: 🔥")   | 10       | integer |

  @performance
  Scenario: Large list processing performance
    Given I have JSON data with 1000 elements
    When I evaluate CEL expression "data.filter(x, x % 2 == 0).size()" multiple times
    Then the cache hit rate should be greater than 75%

  @edge-cases
  Scenario: Empty collections handling
    Given I have JSON data:
      """
      {"empty_list": [], "empty_object": {}}
      """
    When I evaluate CEL expression 'size(empty_list) == 0 && size(empty_object) == 0'
    Then the result should be "true"
    And the result type should be "boolean"
