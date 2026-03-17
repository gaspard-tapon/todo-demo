import 'dart:io';
import 'package:test/test.dart';
import 'package:todo_server/database.dart';
import 'package:todo_server/repository/todo_repository.dart';

/// Integration tests — require a running PostgreSQL instance.
/// Set TEST_DATABASE_URL env var, e.g.:
///   TEST_DATABASE_URL=postgres://todo:todo@localhost:5432/todo_test dart test test/integration/
void main() {
  final databaseUrl = Platform.environment['TEST_DATABASE_URL'];

  if (databaseUrl == null) {
    print('Skipping integration tests: TEST_DATABASE_URL not set');
    return;
  }

  late Database db;
  late ServerTodoRepository repo;

  setUpAll(() async {
    db = Database(connectionString: databaseUrl);
    await db.initialize();
    repo = ServerTodoRepository(db);
  });

  tearDown(() async {
    await db.execute('DELETE FROM todos');
  });

  tearDownAll(() async {
    await db.close();
  });

  group('ServerTodoRepository (integration)', () {
    test('create and retrieve a todo', () async {
      final created = await repo.create('Integration test todo', null);

      expect(created.id, isNotEmpty);
      expect(created.title, 'Integration test todo');
      expect(created.isCompleted, false);

      final fetched = await repo.getById(created.id);
      expect(fetched.title, 'Integration test todo');
      expect(fetched.id, created.id);
    });

    test('create with description', () async {
      final created = await repo.create('With desc', 'A description');

      expect(created.description, 'A description');
    });

    test('getAll returns all todos ordered by created_at DESC', () async {
      await repo.create('First', null);
      await repo.create('Second', null);
      await repo.create('Third', null);

      final todos = await repo.getAll();

      expect(todos, hasLength(3));
      expect(todos[0].title, 'Third');
      expect(todos[2].title, 'First');
    });

    test('update marks todo as completed', () async {
      final created = await repo.create('Complete me', null);

      final updated = await repo.update(created.id, isCompleted: true);

      expect(updated.isCompleted, true);
      expect(updated.title, 'Complete me');
    });

    test('update changes title', () async {
      final created = await repo.create('Old title', null);

      final updated = await repo.update(created.id, title: 'New title');

      expect(updated.title, 'New title');
    });

    test('delete removes todo', () async {
      final created = await repo.create('Delete me', null);

      await repo.delete(created.id);

      expect(
        () => repo.getById(created.id),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('getById throws NotFoundException for non-existent id', () async {
      expect(
        () => repo.getById('00000000-0000-0000-0000-000000000000'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('delete throws NotFoundException for non-existent id', () async {
      expect(
        () => repo.delete('00000000-0000-0000-0000-000000000000'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
