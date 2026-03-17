/// Tests unitaires de [ApiTodoRepository].
///
/// Ce fichier vérifie que le repository HTTP communique correctement avec
/// l'API REST du serveur. On utilise [MockClient] (du package `http/testing`)
/// pour simuler les réponses du serveur sans faire de vrais appels réseau.
///
/// Pour chaque méthode du repository, on vérifie :
/// 1. Que la bonne méthode HTTP est utilisée (GET, POST, PUT, DELETE)
/// 2. Que l'URL appelée est correcte
/// 3. Que le corps de la requête contient les bonnes données (si applicable)
/// 4. Que la réponse est correctement désérialisée en objet [Todo]
/// 5. Qu'une exception est levée en cas d'erreur serveur (code != 2xx)
///
/// Lancer avec :
/// ```bash
/// flutter test test/unit/repositories/api_todo_repository_test.dart
/// ```
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:todo/repositories/api_todo_repository.dart';

void main() {
  /// URL de base utilisée pour tous les tests.
  /// En production, cette valeur vient du provider `baseUrlProvider`.
  const baseUrl = 'http://localhost:8080';

  /// Date fixe au format ISO 8601 pour les données de test.
  final now = DateTime(2026, 3, 17).toIso8601String();

  /// Génère une liste de deux todos en JSON, telle que renvoyée par
  /// l'endpoint GET /api/todos. Utilisée comme donnée de référence
  /// dans plusieurs tests.
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

    // ── GET /api/todos ─────────────────────────────────────────────

    group('getAll', () {
      /// Simule une réponse 200 avec une liste de 2 todos en JSON.
      /// Vérifie que le repository :
      /// - envoie un GET sur /api/todos
      /// - parse correctement la liste en objets Todo
      /// - retourne le bon nombre d'éléments avec les bonnes valeurs
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

      /// Simule une erreur serveur (500). Vérifie que le repository
      /// lève une exception au lieu de retourner une liste vide ou
      /// corrompue. Cela permet à la couche UI d'afficher un message
      /// d'erreur approprié.
      test('throws on non-200 status', () async {
        final client = MockClient((_) async => http.Response('Server error', 500));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.getAll(), throwsException);
      });
    });

    // ── GET /api/todos/:id ─────────────────────────────────────────

    group('getById', () {
      /// Simule une réponse 200 avec un seul todo en JSON.
      /// Vérifie que l'URL inclut bien l'id demandé et que l'objet
      /// retourné a les bonnes propriétés.
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

      /// Simule une réponse 404 (todo introuvable). Vérifie qu'une
      /// exception est levée, ce qui correspond au cas où l'utilisateur
      /// essaie d'accéder à un todo qui a été supprimé.
      test('throws on 404', () async {
        final client = MockClient((_) async => http.Response('Not found', 404));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.getById('999'), throwsException);
      });
    });

    // ── POST /api/todos ────────────────────────────────────────────

    group('create', () {
      /// Simule la création d'un todo. Vérifie que :
      /// - la méthode HTTP est bien POST
      /// - l'URL est /api/todos
      /// - le corps de la requête contient le titre et la description
      /// - le todo retourné a l'id généré par le serveur (ici '3')
      /// - isCompleted est bien à false par défaut
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

    // ── PUT /api/todos/:id ─────────────────────────────────────────

    group('update', () {
      /// Simule la mise à jour partielle d'un todo (ici, uniquement
      /// le champ `is_completed`). Vérifie que :
      /// - la méthode HTTP est bien PUT
      /// - l'URL inclut l'id du todo
      /// - le corps ne contient QUE les champs modifiés (pas de `title`)
      /// - le todo retourné reflète la modification
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

    // ── DELETE /api/todos/:id ──────────────────────────────────────

    group('delete', () {
      /// Simule la suppression réussie d'un todo (réponse 204 No Content).
      /// Vérifie que la méthode HTTP est DELETE, que l'URL est correcte,
      /// et que la méthode ne lève pas d'exception.
      test('sends DELETE and succeeds on 204', () async {
        final client = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.toString(), '$baseUrl/api/todos/1');
          return http.Response('', 204);
        });
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        await repo.delete('1');
      });

      /// Simule une tentative de suppression d'un todo inexistant (404).
      /// Vérifie qu'une exception est levée pour signaler l'erreur à
      /// la couche appelante.
      test('throws on non-204', () async {
        final client = MockClient((_) async => http.Response('Not found', 404));
        final repo = ApiTodoRepository(client: client, baseUrl: baseUrl);

        expect(() => repo.delete('1'), throwsException);
      });
    });
  });
}
