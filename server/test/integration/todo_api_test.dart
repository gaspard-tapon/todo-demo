import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:todo_server/database.dart';
import 'package:todo_server/repository/todo_repository.dart';
import 'package:todo_server/handlers/todo_handler.dart';
import 'package:todo_server/router.dart';

/// Full API integration tests — require a running PostgreSQL instance.
/// Set TEST_DATABASE_URL env var.
void main() {
  final databaseUrl = Platform.environment['TEST_DATABASE_URL'];

  if (databaseUrl == null) {
    print('Skipping API integration tests: TEST_DATABASE_URL not set');
    return;
  }

  late Database db;
  late HttpServer server;
  late String baseUrl;
  final client = http.Client();

  setUpAll(() async {
    db = Database(connectionString: databaseUrl);
    await db.initialize();

    final repository = ServerTodoRepository(db);
    final handler = TodoHandler(repository);
    final router = createRouter(handler);

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    server = await io.serve(pipeline, 'localhost', 0);
    baseUrl = 'http://localhost:${server.port}';
  });

  tearDown(() async {
    await db.execute('DELETE FROM todos');
  });

  tearDownAll(() async {
    client.close();
    await server.close();
    await db.close();
  });

  group('Todo API (integration)', () {
    test('GET /api/health returns ok', () async {
      final response = await client.get(Uri.parse('$baseUrl/api/health'));

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['status'], 'ok');
    });

    test('full CRUD flow', () async {
      // 1. List is empty
      var response = await client.get(Uri.parse('$baseUrl/api/todos'));
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), isEmpty);

      // 2. Create a todo
      response = await client.post(
        Uri.parse('$baseUrl/api/todos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': 'API test todo', 'description': 'Test desc'}),
      );
      expect(response.statusCode, 201);
      final created = jsonDecode(response.body) as Map<String, dynamic>;
      expect(created['title'], 'API test todo');
      expect(created['description'], 'Test desc');
      expect(created['is_completed'], false);
      final todoId = created['id'] as String;

      // 3. Get by id
      response = await client.get(Uri.parse('$baseUrl/api/todos/$todoId'));
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['title'], 'API test todo');

      // 4. Update — mark as completed
      response = await client.put(
        Uri.parse('$baseUrl/api/todos/$todoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_completed': true}),
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['is_completed'], true);

      // 5. List has one todo
      response = await client.get(Uri.parse('$baseUrl/api/todos'));
      expect(jsonDecode(response.body), hasLength(1));

      // 6. Delete
      response = await client.delete(Uri.parse('$baseUrl/api/todos/$todoId'));
      expect(response.statusCode, 204);

      // 7. List is empty again
      response = await client.get(Uri.parse('$baseUrl/api/todos'));
      expect(jsonDecode(response.body), isEmpty);
    });

    test('POST /api/todos returns 400 without title', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/api/todos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': 'No title'}),
      );
      expect(response.statusCode, 400);
    });

    test('GET /api/todos/:id returns 404 for missing todo', () async {
      final response = await client.get(
        Uri.parse('$baseUrl/api/todos/00000000-0000-0000-0000-000000000000'),
      );
      expect(response.statusCode, 404);
    });
  });
}
