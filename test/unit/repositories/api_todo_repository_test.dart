import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:todo/repositories/api_todo_repository.dart';

void main() {
  const baseUrl = 'http://localhost:8080';
  final now = DateTime(2026, 3, 17).toIso8601String();

  List<Map<String, dynamic>> sampleTodosJson() => [
        {
          'id': '1',
          'title': 'First todo',
          'description': null,
          'is_completed': false,
          'created_at': now,
          'updated_at': now,
        },
        {
          'id': '2',
          'title': 'Second todo',
          'description': 'A description',
          'is_completed': true,
          'created_at': now,
          'updated_at': now,
        },
      ];

  group('ApiTodoRepository', () {
    group('getAll', () {
      test('returns list of todos on 200', () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), '$baseUrl/api/todos');
          expect(request.method, 'GET');
          return http.Response(jsonEncode(sampleTodosJson()), 200);
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        final todos = await repo.getAll();

        expect(todos, hasLength(2));
        expect(todos[0].title, 'First todo');
        expect(todos[1].isCompleted, true);
      });

      test('throws on non-200 status', () async {
        final client = MockClient((_) async => http.Response('Server error', 500));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.getAll(), throwsException);
      });
    });

    group('getById', () {
      test('returns todo on 200', () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), '$baseUrl/api/todos/1');
          return http.Response(jsonEncode(sampleTodosJson()[0]), 200);
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        final todo = await repo.getById('1');
        expect(todo.id, '1');
        expect(todo.title, 'First todo');
      });

      test('throws on 404', () async {
        final client = MockClient((_) async => http.Response('Not found', 404));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.getById('999'), throwsException);
      });
    });

    group('create', () {
      test('sends POST with correct body and returns created todo', () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$baseUrl/api/todos');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['title'], 'New todo');
          expect(body['description'], isNull);

          return http.Response(
            jsonEncode({
              'id': '3',
              'title': 'New todo',
              'description': null,
              'is_completed': false,
              'created_at': now,
              'updated_at': now,
            }),
            201,
          );
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        final todo = await repo.create(title: 'New todo');
        expect(todo.id, '3');
        expect(todo.title, 'New todo');
        expect(todo.isCompleted, false);
      });
    });

    group('update', () {
      test('sends PUT with partial body', () async {
        final client = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.toString(), '$baseUrl/api/todos/1');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['is_completed'], true);
          expect(body.containsKey('title'), false);

          return http.Response(
            jsonEncode({
              'id': '1',
              'title': 'First todo',
              'description': null,
              'is_completed': true,
              'created_at': now,
              'updated_at': now,
            }),
            200,
          );
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        final todo = await repo.update('1', isCompleted: true);
        expect(todo.isCompleted, true);
      });
    });

    group('delete', () {
      test('sends DELETE and succeeds on 204', () async {
        final client = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.toString(), '$baseUrl/api/todos/1');
          return http.Response('', 204);
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        await repo.delete('1'); // Should not throw
      });

      test('throws on non-204', () async {
        final client = MockClient((_) async => http.Response('Not found', 404));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.delete('1'), throwsException);
      });
    });
  });
}
