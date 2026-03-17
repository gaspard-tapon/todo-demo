import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/todo_providers.dart';
import '../widgets/todo_item.dart';
import '../widgets/todo_filters.dart';
import '../widgets/add_todo_dialog.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTodos = ref.watch(filteredTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const TodoFilters(),
          Expanded(
            child: filteredTodos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(todoListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (todos) {
                if (todos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No todos yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return TodoItem(
                      todo: todo,
                      onToggle: () =>
                          ref.read(todoListProvider.notifier).toggleTodo(todo),
                      onDelete: () =>
                          ref.read(todoListProvider.notifier).deleteTodo(todo.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<Map<String, String?>>(
            context: context,
            builder: (_) => const AddTodoDialog(),
          );
          if (result != null) {
            await ref.read(todoListProvider.notifier).addTodo(
                  title: result['title']!,
                  description: result['description'],
                );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
