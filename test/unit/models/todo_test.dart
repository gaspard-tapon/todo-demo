/// Tests unitaires du modèle [Todo].
///
/// Ce fichier vérifie le bon fonctionnement du modèle de données Todo,
/// qui est la structure centrale de l'application. On teste ici :
///
/// - **Désérialisation JSON (`fromJson`)** : conversion d'une Map JSON
///   (telle que renvoyée par l'API) en objet [Todo] Dart.
/// - **Sérialisation JSON (`toJson`)** : conversion inverse, d'un objet
///   [Todo] vers une Map JSON prête à être envoyée à l'API.
/// - **Copie partielle (`copyWith`)** : création d'une copie du Todo en
///   ne modifiant que certains champs (immutabilité).
/// - **Égalité par valeur** : deux objets Todo avec les mêmes données
///   doivent être considérés comme égaux (opérateur `==` et `hashCode`).
/// - **Représentation textuelle (`toString`)** : vérification que les
///   informations clés apparaissent dans l'affichage debug.
///
/// Lancer avec :
/// ```bash
/// flutter test test/unit/models/todo_test.dart
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:todo/models/todo.dart';

void main() {
  group('Todo Model', () {
    /// Date fixe utilisée dans tous les tests pour garantir des résultats
    /// déterministes (pas de dépendance à DateTime.now()).
    final now = DateTime(2026, 3, 17, 10, 0, 0);

    /// Exemple de JSON tel que renvoyé par l'API REST du serveur.
    /// Les clés utilisent le format snake_case (convention côté serveur).
    final sampleJson = {
      'id': '123',
      'title': 'Buy milk',
      'description': 'From the store',
      'is_completed': false,
      'created_at': '2026-03-17T10:00:00.000',
      'updated_at': '2026-03-17T10:00:00.000',
    };

    /// Objet Todo de référence, construit manuellement, qui correspond
    /// au JSON ci-dessus. Utilisé pour les tests de sérialisation et copyWith.
    final sampleTodo = Todo(
      id: '123',
      title: 'Buy milk',
      description: 'From the store',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    // ── Désérialisation (JSON → objet Dart) ──────────────────────────

    group('fromJson', () {
      /// Vérifie que tous les champs sont correctement extraits du JSON :
      /// id, title, description, isCompleted, createdAt.
      test('creates correct Todo from valid JSON', () {
        final todo = Todo.fromJson(sampleJson);

        expect(todo.id, '123');
        expect(todo.title, 'Buy milk');
        expect(todo.description, 'From the store');
        expect(todo.isCompleted, false);
        expect(todo.createdAt, now);
      });

      /// Vérifie que le champ `description` peut être null sans provoquer
      /// d'erreur. En effet, la description est optionnelle à la création
      /// d'un todo.
      test('handles null description', () {
        final json = Map<String, dynamic>.from(sampleJson);
        json['description'] = null;

        final todo = Todo.fromJson(json);
        expect(todo.description, isNull);
      });

      /// Vérifie que si le champ `is_completed` est absent du JSON
      /// (par ex. un ancien enregistrement), la valeur par défaut est `false`.
      test('defaults isCompleted to false when missing', () {
        final json = Map<String, dynamic>.from(sampleJson);
        json.remove('is_completed');

        final todo = Todo.fromJson(json);
        expect(todo.isCompleted, false);
      });
    });

    // ── Sérialisation (objet Dart → JSON) ────────────────────────────

    group('toJson', () {
      /// Vérifie que `toJson` produit une Map avec les bonnes clés
      /// snake_case et les bonnes valeurs, prête à être encodée en JSON
      /// pour l'envoi à l'API.
      test('produces correct map', () {
        final json = sampleTodo.toJson();

        expect(json['id'], '123');
        expect(json['title'], 'Buy milk');
        expect(json['description'], 'From the store');
        expect(json['is_completed'], false);
        expect(json['created_at'], contains('2026-03-17'));
      });

      /// Test aller-retour : on part d'un JSON, on crée un Todo, on le
      /// resérialise, puis on le redésérialise. L'objet final doit être
      /// identique à l'objet intermédiaire. Cela garantit qu'aucune donnée
      /// n'est perdue lors des conversions.
      test('roundtrip fromJson -> toJson preserves data', () {
        final todo = Todo.fromJson(sampleJson);
        final json = todo.toJson();
        final restored = Todo.fromJson(json);

        expect(restored, todo);
      });
    });

    // ── Copie partielle (immutabilité) ───────────────────────────────

    group('copyWith', () {
      /// Vérifie que `copyWith` ne modifie que le champ demandé
      /// (ici `isCompleted`) et conserve tous les autres champs intacts.
      /// C'est essentiel car le modèle est immuable : on ne modifie jamais
      /// un Todo existant, on en crée une copie.
      test('preserves unchanged fields', () {
        final updated = sampleTodo.copyWith(isCompleted: true);

        expect(updated.id, sampleTodo.id);
        expect(updated.title, sampleTodo.title);
        expect(updated.description, sampleTodo.description);
        expect(updated.isCompleted, true);
      });

      /// Vérifie qu'on peut modifier le titre tout en gardant l'id
      /// et les autres champs inchangés.
      test('updates title', () {
        final updated = sampleTodo.copyWith(title: 'Buy eggs');
        expect(updated.title, 'Buy eggs');
        expect(updated.id, sampleTodo.id);
      });
    });

    // ── Égalité par valeur ───────────────────────────────────────────

    group('equality', () {
      /// Deux instances distinctes avec les mêmes données doivent être
      /// considérées comme égales. C'est important pour que les comparaisons
      /// dans les listes et les tests fonctionnent correctement.
      test('two todos with same data are equal', () {
        final todo1 = Todo(
          id: '1',
          title: 'Test',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
        final todo2 = Todo(
          id: '1',
          title: 'Test',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
        expect(todo1, todo2);
      });

      /// Deux todos avec des ids différents ne doivent PAS être égaux,
      /// même si tous les autres champs sont identiques.
      test('two todos with different ids are not equal', () {
        final todo1 = Todo(
          id: '1', title: 'Test', isCompleted: false,
          createdAt: now, updatedAt: now,
        );
        final todo2 = Todo(
          id: '2', title: 'Test', isCompleted: false,
          createdAt: now, updatedAt: now,
        );
        expect(todo1, isNot(todo2));
      });
    });

    /// Vérifie que `toString()` inclut le titre et l'id, ce qui facilite
    /// le débogage quand un test échoue et affiche l'objet.
    test('toString contains key info', () {
      expect(sampleTodo.toString(), contains('Buy milk'));
      expect(sampleTodo.toString(), contains('123'));
    });
  });
}
