Feature: Complete a todo
  As a user
  I want to mark a todo as completed
  So that I can track my progress

  Scenario: Mark a todo as completed
    Given I am on the todo list page
    And a todo "Write tests" exists
    When I tap the checkbox for "Write tests"
    Then "Write tests" should be marked as completed
