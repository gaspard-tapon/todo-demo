import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';
import 'todo_repository.dart';

class ApiTodoRepository implements TodoRepository {
  final http.Client client;
  final String baseUrl;

  ApiTodoRepository({required this.client, required this.baseUrl});

  @override
  Future<List<Todo>> getAll() async {
    final response = await client.get(Uri.parse('$baseUrl/api/todos'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load todos: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Todo> getById(String id) async {
    final response = await client.get(Uri.parse('$baseUrl/api/todos/$id'));
    if (response.statusCode != 200) {
      throw Exception('Todo not found');
    }
    return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Todo> create({required String title, String? description}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'description': description}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create todo: ${response.body}');
    }
    return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Todo> update(String id, {String? title, String? description, bool? isCompleted}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (isCompleted != null) body['is_completed'] = isCompleted;

    final response = await client.put(
      Uri.parse('$baseUrl/api/todos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update todo: ${response.body}');
    }
    return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    final response = await client.delete(Uri.parse('$baseUrl/api/todos/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete todo: ${response.body}');
    }
  }
}
