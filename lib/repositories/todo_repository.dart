import '../models/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<Todo> getById(String id);
  Future<Todo> create({required String title, String? description});
  Future<Todo> update(String id, {String? title, String? description, bool? isCompleted});
  Future<void> delete(String id);
}
