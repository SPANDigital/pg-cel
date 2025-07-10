Feature: PostgreSQL Integration
  In order to use CEL expressions in PostgreSQL queries
  As a database user
  I need to be able to call CEL functions in SQL statements

  Background:
    Given pg-cel extension is loaded
    And I have a test table with data

  Scenario: Basic SQL function call
    When I execute SQL:
      """
      SELECT cel_eval('1 + 1') as result;
      """
    Then the SQL result should be "2"

  Scenario: CEL function with table data
    When I execute SQL:
      """
      SELECT name, cel_eval('age > 25', json_build_object('age', age)) as is_adult
      FROM test_users
      WHERE name = 'John';
      """
    Then the SQL should return results
    And the "is_adult" column should contain boolean values

  Scenario: CEL function in WHERE clause
    When I execute SQL:
      """
      SELECT name, age
      FROM test_users
      WHERE cel_eval_bool('age >= 30', json_build_object('age', age));
      """
    Then the SQL should return only users aged 30 or above

  Scenario: Complex JSON evaluation in SQL
    Given I have a table with JSON data
    When I execute SQL:
      """
      SELECT 
        id,
        cel_eval('user.profile.email', data) as email,
        cel_eval('user.permissions.size()', data) as permission_count
      FROM json_table
      WHERE cel_eval_bool('user.active', data);
      """
    Then the SQL should return processed JSON data

  Scenario: Aggregation with CEL expressions
    When I execute SQL:
      """
      SELECT 
        AVG(cel_eval_double('score * 1.0', json_build_object('score', score))) as avg_score
      FROM test_scores;
      """
    Then the SQL should return the average score

  Scenario: CEL expression compilation check
    When I execute SQL:
      """
      SELECT cel_compile_check('1 + 1') as is_valid;
      """
    Then the SQL result should be "true"

  Scenario: Invalid expression compilation check
    When I execute SQL:
      """
      SELECT cel_compile_check('1 +') as is_valid;
      """
    Then the SQL result should be "false"

  Scenario: Cache statistics in SQL
    When I execute SQL:
      """
      SELECT cel_cache_stats();
      """
    Then the SQL should return cache statistics as JSON

  Scenario: Transaction isolation
    Given I start a database transaction
    When I evaluate CEL expressions in the transaction
    And I rollback the transaction
    Then the cache should remain consistent

  Scenario Outline: Different CEL return types in SQL
    When I execute SQL:
      """
      SELECT cel_eval_<function>('<expression>') as result;
      """
    Then the SQL result type should be "<sql_type>"

    Examples:
      | function | expression | sql_type |
      | bool     | true       | boolean  |
      | int      | 42         | integer  |
      | double   | 3.14       | numeric  |
      | string   | "hello"    | text     |
