Feature: CEL Caching Performance
  In order to optimize CEL expression evaluation
  As a database administrator
  I need to verify that caching works correctly and improves performance

  Background:
    Given pg-cel extension is loaded

  Scenario: Cache initialization
    When I clear the cache
    Then the program cache should be empty
    And the JSON cache should be empty

  Scenario: Program cache functionality
    Given the cache is cleared
    When I evaluate CEL expression "1 + 1" multiple times
    Then the program cache hit rate should increase
    And the cache should contain the compiled expression

  Scenario: JSON cache functionality
    Given the cache is cleared
    And I have JSON data:
      """
      {"large_object": {"data": [1, 2, 3, 4, 5]}}
      """
    When I evaluate CEL expression "large_object.data.size()" multiple times
    Then the JSON cache hit rate should increase
    And the JSON cache should contain the parsed data

  Scenario: Cache statistics reporting
    Given the cache is cleared
    When I evaluate several different CEL expressions
    And I check cache statistics
    Then I should see cache hit and miss counts
    And I should see cache sizes
    And I should see memory usage information

  Scenario: Cache memory limits
    Given the cache is cleared
    When I fill the cache with many expressions
    Then the cache should respect memory limits
    And older entries should be evicted when limit is reached

  Scenario: Cache key uniqueness
    Given the cache is cleared
    When I evaluate the same expression with different JSON data
    Then each combination should have a unique cache key
    And cache hits should only occur for identical expression+data pairs

  Scenario: Cache persistence across sessions
    Given I evaluate CEL expression "test_expression"
    When I start a new database session
    And I evaluate the same CEL expression "test_expression"
    Then the expression should be cached from the previous session

  Scenario Outline: Cache performance with different data sizes
    Given the cache is cleared
    And I have JSON data with <size> elements
    When I evaluate CEL expression "data.size()" multiple times
    Then the cache hit rate should be greater than <expected_hit_rate>%

    Examples:
      | size | expected_hit_rate |
      | 10   | 70               |
      | 100  | 75               |
      | 1000 | 80               |
