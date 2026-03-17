import 'package:flutter_test/flutter_test.dart';
import 'package:todo/models/todo.dart';

void main() {
  group('Todo Model', () {
    final now = DateTime(2026, 3, 17, 10, 0, 0);
    final sampleJson = {
      'id': '123',
      'title': 'Buy milk',
      'description': 'From the store',
      'is_completed': false,
      'created_at': '2026-03-17T10:00:00.000',
      'updated_at': '2026-03-17T10:00:00.000',
    };

    final sampleTodo = Todo(
      id: '123',
      title: 'Buy milk',
      description: 'From the store',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    group('fromJson', () {
      test('creates correct Todo from valid JSON', () {
        final todo = Todo.fromJson(sampleJson);

        expect(todo.id, '123');
        expect(todo.title, 'Buy milk');
        expect(todo.description, 'From the store');
        expect(todo.isCompleted, false);
        expect(todo.createdAt, now);
      });

      test('handles null description', () {
        final json = Map<String, dynamic>.from(sampleJson);
        json['description'] = null;

        final todo = Todo.fromJson(json);
        expect(todo.description, isNull);
      });

      test('defaults isCompleted to false when missing', () {
        final json = Map<String, dynamic>.from(sampleJson);
        json.remove('is_completed');

        final todo = Todo.fromJson(json);
        expect(todo.isCompleted, false);
      });
    });

    group('toJson', () {
      test('produces correct map', () {
        final json = sampleTodo.toJson();

        expect(json['id'], '123');
        expect(json['title'], 'Buy milk');
        expect(json['description'], 'From the store');
        expect(json['is_completed'], false);
        expect(json['created_at'], contains('2026-03-17'));
      });

      test('roundtrip fromJson -> toJson preserves data', () {
        final todo = Todo.fromJson(sampleJson);
        final json = todo.toJson();
        final restored = Todo.fromJson(json);

        expect(restored, todo);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final updated = sampleTodo.copyWith(isCompleted: true);

        expect(updated.id, sampleTodo.id);
        expect(updated.title, sampleTodo.title);
        expect(updated.description, sampleTodo.description);
        expect(updated.isCompleted, true);
      });

      test('updates title', () {
        final updated = sampleTodo.copyWith(title: 'Buy eggs');
        expect(updated.title, 'Buy eggs');
        expect(updated.id, sampleTodo.id);
      });
    });

    group('equality', () {
      test('two todos with same data are equal', () {
        final todo1 = Todo(
          id: '1',
          title: 'Test',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
        final todo2 = Todo(
          id: '1',
          title: 'Test',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
        expect(todo1, todo2);
      });

      test('two todos with different ids are not equal', () {
        final todo1 = Todo(
          id: '1', title: 'Test', isCompleted: false,
          createdAt: now, updatedAt: now,
        );
        final todo2 = Todo(
          id: '2', title: 'Test', isCompleted: false,
          createdAt: now, updatedAt: now,
        );
        expect(todo1, isNot(todo2));
      });
    });

    test('toString contains key info', () {
      expect(sampleTodo.toString(), contains('Buy milk'));
      expect(sampleTodo.toString(), contains('123'));
    });
  });
}
