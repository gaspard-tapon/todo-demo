import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/app.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/providers/todo_providers.dart';
import 'package:todo/repositories/todo_repository.dart';

/// In-memory fake repository for acceptance tests (no external dependencies)
class FakeTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];
  int _nextId = 1;

  @override
  Future<List<Todo>> getAll() async => List.unmodifiable(_todos.reversed);

  @override
  Future<Todo> getById(String id) async {
    return _todos.firstWhere((t) => t.id == id);
  }

  @override
  Future<Todo> create({required String title, String? description}) async {
    final now = DateTime.now();
    final todo = Todo(
      id: '${_nextId++}',
      title: title,
      description: description,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    _todos.add(todo);
    return todo;
  }

  @override
  Future<Todo> update(String id,
      {String? title, String? description, bool? isCompleted}) async {
    final index = _todos.indexWhere((t) => t.id == id);
    final old = _todos[index];
    final updated = old.copyWith(
      title: title ?? old.title,
      description: description ?? old.description,
      isCompleted: isCompleted ?? old.isCompleted,
      updatedAt: DateTime.now(),
    );
    _todos[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _todos.removeWhere((t) => t.id == id);
  }
}

/// Acceptance tests implementing Gherkin scenarios manually
/// (bdd_widget_test generates from .feature files, but here we show
/// the step definitions pattern explicitly for educational purposes)
void main() {
  late FakeTodoRepository repo;

  setUp(() {
    repo = FakeTodoRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ],
      child: const App(),
    );
  }

  group('Feature: Create a todo', () {
    testWidgets('Scenario: Create a simple todo', (tester) async {
      // Given I am on the todo list page
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // And the list is empty
      expect(find.text('No todos yet'), findsOneWidget);

      // When I tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // And I enter "Buy groceries" as the title
      await tester.enterText(find.byType(TextFormField).first, 'Buy groceries');

      // And I tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Then I should see "Buy groceries" in the todo list
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('Scenario: Cannot create a todo without a title',
        (tester) async {
      // Given I am on the todo list page
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // When I tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // And I leave the title empty (don't enter anything)

      // And I tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Then I should see a validation error "Title is required"
      expect(find.text('Title is required'), findsOneWidget);
    });
  });

  group('Feature: Complete a todo', () {
    testWidgets('Scenario: Mark a todo as completed', (tester) async {
      // Given I am on the todo list page
      // And a todo "Write tests" exists
      await repo.create(title: 'Write tests');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Write tests'), findsOneWidget);

      // When I tap the checkbox for "Write tests"
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Then "Write tests" should be marked as completed
      // (the text gets a line-through decoration)
      final textWidget = tester.widget<Text>(find.text('Write tests'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('Feature: Delete a todo', () {
    testWidgets('Scenario: Delete an existing todo', (tester) async {
      // Given I am on the todo list page
      // And a todo "Old task" exists
      await repo.create(title: 'Old task');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Old task'), findsOneWidget);

      // When I tap the delete button for "Old task"
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Then "Old task" should no longer be in the list
      expect(find.text('Old task'), findsNothing);
    });
  });
}
