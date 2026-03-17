import '../database.dart';

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

class TodoModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static TodoModel fromRow(Map<String, dynamic> row) {
    return TodoModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      isCompleted: row['is_completed'] as bool,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
    );
  }
}

class ServerTodoRepository {
  final Database _db;

  ServerTodoRepository(this._db);

  Future<List<TodoModel>> getAll() async {
    final result = await _db.execute(
      'SELECT * FROM todos ORDER BY created_at DESC',
    );
    return result
        .map((row) => TodoModel.fromRow(row.toColumnMap()))
        .toList();
  }

  Future<TodoModel> getById(String id) async {
    final result = await _db.execute(
      'SELECT * FROM todos WHERE id = @id',
      {'id': id},
    );
    if (result.isEmpty) {
      throw NotFoundException('Todo with id $id not found');
    }
    return TodoModel.fromRow(result.first.toColumnMap());
  }

  Future<TodoModel> create(String title, String? description) async {
    final result = await _db.execute(
      'INSERT INTO todos (title, description) VALUES (@title, @description) RETURNING *',
      {'title': title, 'description': description},
    );
    return TodoModel.fromRow(result.first.toColumnMap());
  }

  Future<TodoModel> update(
    String id, {
    String? title,
    String? description,
    bool? isCompleted,
  }) async {
    final sets = <String>[];
    final params = <String, dynamic>{'id': id};

    if (title != null) {
      sets.add('title = @title');
      params['title'] = title;
    }
    if (description != null) {
      sets.add('description = @description');
      params['description'] = description;
    }
    if (isCompleted != null) {
      sets.add('is_completed = @isCompleted');
      params['isCompleted'] = isCompleted;
    }
    sets.add('updated_at = NOW()');

    final result = await _db.execute(
      'UPDATE todos SET ${sets.join(', ')} WHERE id = @id RETURNING *',
      params,
    );
    if (result.isEmpty) {
      throw NotFoundException('Todo with id $id not found');
    }
    return TodoModel.fromRow(result.first.toColumnMap());
  }

  Future<void> delete(String id) async {
    final result = await _db.execute(
      'DELETE FROM todos WHERE id = @id RETURNING id',
      {'id': id},
    );
    if (result.isEmpty) {
      throw NotFoundException('Todo with id $id not found');
    }
  }
}
