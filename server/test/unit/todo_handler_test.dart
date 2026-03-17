import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:todo_server/handlers/todo_handler.dart';
import 'package:todo_server/repository/todo_repository.dart';

/// In-memory fake repository for unit testing handlers
class FakeServerTodoRepository implements ServerTodoRepository {
  final List<TodoModel> _todos = [];
  int _nextId = 1;

  @override
  Future<List<TodoModel>> getAll() async => List.unmodifiable(_todos);

  @override
  Future<TodoModel> getById(String id) async {
    final todo = _todos.where((t) => t.id == id).firstOrNull;
    if (todo == null) throw NotFoundException('Todo $id not found');
    return todo;
  }

  @override
  Future<TodoModel> create(String title, String? description) async {
    final now = DateTime.now();
    final todo = TodoModel(
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
  Future<TodoModel> update(String id, {String? title, String? description, bool? isCompleted}) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) throw NotFoundException('Todo $id not found');
    final old = _todos[index];
    final updated = TodoModel(
      id: old.id,
      title: title ?? old.title,
      description: description ?? old.description,
      isCompleted: isCompleted ?? old.isCompleted,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _todos[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) throw NotFoundException('Todo $id not found');
    _todos.removeAt(index);
  }
}

void main() {
  late FakeServerTodoRepository repository;
  late TodoHandler handler;

  setUp(() {
    repository = FakeServerTodoRepository();
    handler = TodoHandler(repository);
  });

  Request makeRequest(String method, String path, {String? body}) {
    return Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body,
      headers: body != null ? {'Content-Type': 'application/json'} : {},
    );
  }

  group('TodoHandler', () {
    group('GET /api/todos', () {
      test('returns empty list when no todos', () async {
        final response = await handler.getAll(makeRequest('GET', '/api/todos'));

        expect(response.statusCode, 200);
        final body = jsonDecode(await response.readAsString()) as List;
        expect(body, isEmpty);
      });

      test('returns all todos', () async {
        await repository.create('Todo 1', null);
        await repository.create('Todo 2', 'Description');

        final response = await handler.getAll(makeRequest('GET', '/api/todos'));
        final body = jsonDecode(await response.readAsString()) as List;

        expect(body, hasLength(2));
        expect(body[0]['title'], 'Todo 1');
        expect(body[1]['title'], 'Todo 2');
      });
    });

    group('GET /api/todos/:id', () {
      test('returns todo by id', () async {
        await repository.create('My todo', null);

        final response = await handler.getById(makeRequest('GET', '/api/todos/1'), '1');

        expect(response.statusCode, 200);
        final body = jsonDecode(await response.readAsString()) as Map;
        expect(body['title'], 'My todo');
      });

      test('returns 404 for non-existent todo', () async {
        final response = await handler.getById(makeRequest('GET', '/api/todos/999'), '999');

        expect(response.statusCode, 404);
      });
    });

    group('POST /api/todos', () {
      test('creates a todo with valid title', () async {
        final response = await handler.create(
          makeRequest('POST', '/api/todos', body: jsonEncode({'title': 'New todo'})),
        );

        expect(response.statusCode, 201);
        final body = jsonDecode(await response.readAsString()) as Map;
        expect(body['title'], 'New todo');
        expect(body['is_completed'], false);
      });

      test('returns 400 when title is missing', () async {
        final response = await handler.create(
          makeRequest('POST', '/api/todos', body: jsonEncode({})),
        );

        expect(response.statusCode, 400);
        final body = jsonDecode(await response.readAsString()) as Map;
        expect(body['error'], contains('Title is required'));
      });

      test('returns 400 when title is empty', () async {
        final response = await handler.create(
          makeRequest('POST', '/api/todos', body: jsonEncode({'title': '  '})),
        );

        expect(response.statusCode, 400);
      });
    });

    group('PUT /api/todos/:id', () {
      test('updates todo completion status', () async {
        await repository.create('My todo', null);

        final response = await handler.update(
          makeRequest('PUT', '/api/todos/1', body: jsonEncode({'is_completed': true})),
          '1',
        );

        expect(response.statusCode, 200);
        final body = jsonDecode(await response.readAsString()) as Map;
        expect(body['is_completed'], true);
      });

      test('returns 404 for non-existent todo', () async {
        final response = await handler.update(
          makeRequest('PUT', '/api/todos/999', body: jsonEncode({'title': 'Updated'})),
          '999',
        );

        expect(response.statusCode, 404);
      });
    });

    group('DELETE /api/todos/:id', () {
      test('deletes existing todo', () async {
        await repository.create('To delete', null);

        final response = await handler.delete(makeRequest('DELETE', '/api/todos/1'), '1');

        expect(response.statusCode, 204);
        expect(await repository.getAll(), isEmpty);
      });

      test('returns 404 for non-existent todo', () async {
        final response = await handler.delete(makeRequest('DELETE', '/api/todos/999'), '999');

        expect(response.statusCode, 404);
      });
    });
  });
}
