/// Tests d'acceptance (BDD) de l'application Todo.
///
/// Ce fichier implémente les scénarios Gherkin définis dans les fichiers
/// `.feature` du dossier `test/acceptance/features/` :
///
/// - **create_todo.feature** : création d'un todo + validation si titre vide
/// - **complete_todo.feature** : cocher un todo comme terminé
/// - **delete_todo.feature** : supprimer un todo existant
///
/// Chaque `testWidgets` correspond exactement à un scénario Gherkin et suit
/// la structure Given / When / Then via des commentaires inline.
///
/// Les tests utilisent un [FakeTodoRepository] en mémoire pour s'isoler
/// complètement de l'API et de la base de données. L'arbre de widgets
/// complet (App → écrans → composants) est instancié via [ProviderScope]
/// avec un override du repository.
///
/// Lancer avec :
/// ```bash
/// flutter test test/acceptance/
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/app.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/providers/todo_providers.dart';
import 'package:todo/repositories/todo_repository.dart';

/// Implémentation en mémoire de [TodoRepository] pour les tests d'acceptance.
///
/// Stocke les todos dans une simple liste. Pas d'appel réseau, pas de base
/// de données : les tests sont rapides, déterministes et isolés.
/// L'id est un compteur auto-incrémenté à partir de 1.
class FakeTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];
  int _nextId = 1;

  @override
  Future<List<Todo>> getAll() async => List.unmodifiable(_todos.reversed);

  @override
  Future<Todo> getById(String id) async {
    return _todos.firstWhere((t) => t.id == id);
  }

  @override
  Future<Todo> create({required String title, String? description}) async {
    final now = DateTime.now();
    final todo = Todo(
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
  Future<Todo> update(String id,
      {String? title, String? description, bool? isCompleted}) async {
    final index = _todos.indexWhere((t) => t.id == id);
    final old = _todos[index];
    final updated = old.copyWith(
      title: title ?? old.title,
      description: description ?? old.description,
      isCompleted: isCompleted ?? old.isCompleted,
      updatedAt: DateTime.now(),
    );
    _todos[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _todos.removeWhere((t) => t.id == id);
  }
}

void main() {
  late FakeTodoRepository repo;

  /// Avant chaque test, on recrée un repository vierge pour garantir
  /// l'isolation entre les scénarios (pas d'état résiduel).
  setUp(() {
    repo = FakeTodoRepository();
  });

  /// Construit l'application complète avec le [FakeTodoRepository] injecté
  /// via Riverpod. Cela remplace le vrai [ApiTodoRepository] sans modifier
  /// le code de production.
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ],
      child: const App(),
    );
  }

  // ── Feature : Créer un todo ──────────────────────────────────────

  group('Feature: Create a todo', () {
    /// Scénario : Créer un todo simple.
    ///
    /// Correspond à create_todo.feature, scénario 1.
    /// L'utilisateur arrive sur la liste vide, appuie sur le bouton "+",
    /// saisit un titre, valide, et vérifie que le todo apparaît dans la liste.
    testWidgets('Scenario: Create a simple todo', (tester) async {
      // Given : je suis sur la page de la liste des todos
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // And : la liste est vide
      expect(find.text('No todos yet'), findsOneWidget);

      // When : j'appuie sur le bouton d'ajout
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // And : je saisis "Buy groceries" comme titre
      await tester.enterText(find.byType(TextFormField).first, 'Buy groceries');

      // And : j'appuie sur Sauvegarder
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Then : "Buy groceries" apparaît dans la liste des todos
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    /// Scénario : Impossible de créer un todo sans titre.
    ///
    /// Correspond à create_todo.feature, scénario 2.
    /// L'utilisateur ouvre le formulaire, ne saisit rien, appuie sur
    /// Sauvegarder, et vérifie qu'un message de validation s'affiche.
    testWidgets('Scenario: Cannot create a todo without a title',
        (tester) async {
      // Given : je suis sur la page de la liste des todos
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // When : j'appuie sur le bouton d'ajout
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // And : je laisse le titre vide

      // And : j'appuie sur Sauvegarder
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Then : un message d'erreur "Title is required" s'affiche
      expect(find.text('Title is required'), findsOneWidget);
    });
  });

  // ── Feature : Compléter un todo ──────────────────────────────────

  group('Feature: Complete a todo', () {
    /// Scénario : Cocher un todo comme terminé.
    ///
    /// Correspond à complete_todo.feature.
    /// Un todo "Write tests" existe déjà. L'utilisateur coche la checkbox,
    /// et le texte doit passer en style barré (line-through) pour indiquer
    /// qu'il est terminé.
    testWidgets('Scenario: Mark a todo as completed', (tester) async {
      // Given : un todo "Write tests" existe
      await repo.create(title: 'Write tests');

      // And : je suis sur la page de la liste des todos
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Write tests'), findsOneWidget);

      // When : je coche la checkbox de "Write tests"
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Then : "Write tests" est affiché avec un style barré (completed)
      final textWidget = tester.widget<Text>(find.text('Write tests'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  // ── Feature : Supprimer un todo ──────────────────────────────────

  group('Feature: Delete a todo', () {
    /// Scénario : Supprimer un todo existant.
    ///
    /// Correspond à delete_todo.feature.
    /// Un todo "Old task" existe déjà. L'utilisateur appuie sur l'icône
    /// de suppression, et le todo disparaît de la liste.
    testWidgets('Scenario: Delete an existing todo', (tester) async {
      // Given : un todo "Old task" existe
      await repo.create(title: 'Old task');

      // And : je suis sur la page de la liste des todos
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Old task'), findsOneWidget);

      // When : j'appuie sur le bouton de suppression de "Old task"
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Then : "Old task" n'apparaît plus dans la liste
      expect(find.text('Old task'), findsNothing);
    });
  });
}
