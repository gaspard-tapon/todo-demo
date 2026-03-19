import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import '../repositories/api_todo_repository.dart';

enum TodoFilter { all, active, completed }

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

const _defaultBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

final baseUrlProvider = Provider<String>((ref) => _defaultBaseUrl);

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return ApiTodoRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: ref.watch(baseUrlProvider),
  );
});

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  TodoRepository get _repository => ref.read(todoRepositoryProvider);

  @override
  Future<List<Todo>> build() async {
    return _repository.getAll();
  }

  Future<void> addTodo({required String title, String? description}) async {
    await _repository.create(title: title, description: description);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleTodo(Todo todo) async {
    await _repository.update(todo.id, isCompleted: !todo.isCompleted);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteTodo(String id) async {
    await _repository.delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateTodo(String id, {String? title, String? description}) async {
    await _repository.update(id, title: title, description: description);
    ref.invalidateSelf();
    await future;
  }
}

final filteredTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todosAsync = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  return todosAsync.whenData((todos) {
    switch (filter) {
      case TodoFilter.active:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
      case TodoFilter.all:
        return todos;
    }
  });
});
