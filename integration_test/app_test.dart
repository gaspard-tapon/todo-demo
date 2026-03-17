import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/app.dart';
import 'package:todo/providers/todo_providers.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/repositories/todo_repository.dart';

/// In-memory repository for system tests (no external dependencies)
class InMemoryTodoRepository implements TodoRepository {
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
  Future<Todo> update(String id, {String? title, String? description, bool? isCompleted}) async {
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

void main() {
  testWidgets('Full CRUD flow — system test', (tester) async {
    final repo = InMemoryTodoRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repo),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify empty state
    expect(find.text('No todos yet'), findsOneWidget);

    // 2. Create a todo
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('New Todo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'System test todo');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Todo should appear in the list
    expect(find.text('System test todo'), findsOneWidget);
    expect(find.text('No todos yet'), findsNothing);

    // 3. Mark as completed
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // 4. Delete the todo
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    // Should show empty state again
    expect(find.text('System test todo'), findsNothing);
    expect(find.text('No todos yet'), findsOneWidget);
  });

  testWidgets('Filter todos — system test', (tester) async {
    final repo = InMemoryTodoRepository();
    await repo.create(title: 'Active task');
    final completed = await repo.create(title: 'Completed task');
    await repo.update(completed.id, isCompleted: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repo),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // All filter — both visible
    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsOneWidget);

    // Active filter
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);

    // Completed filter
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Active task'), findsNothing);
    expect(find.text('Completed task'), findsOneWidget);
  });
}
