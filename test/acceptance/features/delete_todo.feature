Feature: Delete a todo
  As a user
  I want to delete a todo item
  So that I can remove tasks I no longer need

  Scenario: Delete an existing todo
    Given I am on the todo list page
    And a todo "Old task" exists
    When I tap the delete button for "Old task"
    Then "Old task" should no longer be in the list
