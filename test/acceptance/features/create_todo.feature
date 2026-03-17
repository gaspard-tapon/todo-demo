Feature: Create a todo
  As a user
  I want to create a new todo item
  So that I can track my tasks

  Scenario: Create a simple todo
    Given I am on the todo list page
    And the list is empty
    When I tap the add button
    And I enter "Buy groceries" as the title
    And I tap save
    Then I should see "Buy groceries" in the todo list

  Scenario: Cannot create a todo without a title
    Given I am on the todo list page
    When I tap the add button
    And I leave the title empty
    And I tap save
    Then I should see a validation error "Title is required"
