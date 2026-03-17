import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../repository/todo_repository.dart';

class TodoHandler {
  final ServerTodoRepository _repository;

  TodoHandler(this._repository);

  Future<Response> getAll(Request request) async {
    final todos = await _repository.getAll();
    return Response.ok(
      jsonEncode(todos.map((t) => t.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final todo = await _repository.getById(id);
      return Response.ok(
        jsonEncode(todo.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on NotFoundException {
      return Response.notFound(
        jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> create(Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final title = body['title'] as String?;
    if (title == null || title.trim().isEmpty) {
      return Response(
        400,
        body: jsonEncode({'error': 'Title is required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final description = body['description'] as String?;
    final todo = await _repository.create(title.trim(), description?.trim());
    return Response(
      201,
      body: jsonEncode(todo.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> update(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final todo = await _repository.update(
        id,
        title: body['title'] as String?,
        description: body['description'] as String?,
        isCompleted: body['is_completed'] as bool?,
      );
      return Response.ok(
        jsonEncode(todo.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on NotFoundException {
      return Response.notFound(
        jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      await _repository.delete(id);
      return Response(204);
    } on NotFoundException {
      return Response.notFound(
        jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
