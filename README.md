# Todo List — Flutter Web + Tests & Recette

Application todo list Flutter web avec backend Dart, conçue pour illustrer les 4 niveaux de tests et la recette logicielle (module INFAL34).

## Architecture

```
Flutter Web (frontend) → Dart shelf API (backend) → PostgreSQL (BDD)
```

## Stack technique

- **Frontend** : Flutter web + Riverpod (state management)
- **Backend** : Dart shelf + shelf_router (REST API)
- **Base de données** : PostgreSQL 16
- **Tests** : flutter_test, mockito, integration_test, Gherkin (BDD)
- **CI/CD** : GitHub Actions → Dokploy (webhook)

## Lancer en local

### Prérequis
- Flutter SDK (stable)
- Docker + Docker Compose

### Démarrage

```bash
# Démarrer la base de données + l'application
docker compose up

# L'app est accessible sur http://localhost:8080
```

### Développement (sans Docker)

```bash
# Terminal 1 : PostgreSQL
docker compose up db

# Terminal 2 : Serveur Dart
cd server
dart pub get
DATABASE_URL=postgres://todo:todo@localhost:5432/todo_dev dart run bin/server.dart

# Terminal 3 : Flutter web (hot reload)
flutter run -d chrome
```

## Tests

### Tests unitaires (Développeur)
```bash
# Frontend
flutter test test/unit/

# Backend
cd server && dart test test/unit/
```

### Tests d'intégration (Développeur + QA)
Nécessitent une base PostgreSQL :
```bash
docker compose up db
cd server
TEST_DATABASE_URL=postgres://todo:todo@localhost:5432/todo_dev dart test test/integration/
```

### Tests système — E2E (QA)
```bash
flutter test integration_test/
```

### Tests d'acceptation — BDD (Product Owner + QA)
```bash
flutter test test/acceptance/
```

### Tous les tests + couverture
```bash
flutter test --coverage
```

## Pipeline CI/CD

Le fichier `.github/workflows/ci.yml` exécute automatiquement :

| Job | Niveau de test | Dépendances |
|-----|---------------|-------------|
| `unit-tests` | Tests unitaires | Aucune |
| `acceptance-tests` | Tests acceptation (BDD) | Aucune |
| `integration-tests` | Tests intégration | PostgreSQL |
| `system-tests` | Tests système (E2E) | Dépend de unit + integration |
| `deploy` | Déploiement Dokploy | Dépend de tous les tests |

### Configuration Dokploy

1. Créer un projet sur Dokploy
2. Configurer le webhook
3. Ajouter le secret `DOKPLOY_WEBHOOK_URL` dans les settings GitHub du repo
4. Configurer la variable d'environnement `DATABASE_URL` dans Dokploy

## Documentation

- [`docs/agile_roles_testing.md`](docs/agile_roles_testing.md) — Rôles agile et responsabilités de tests
- [`docs/test_plan.md`](docs/test_plan.md) — Cahier de recette

## Structure du projet

```
todo/
├── lib/                          # Frontend Flutter
│   ├── models/todo.dart          # Modèle Todo
│   ├── repositories/             # Couche d'accès aux données
│   ├── providers/                # State management (Riverpod)
│   └── ui/                       # Écrans et widgets
├── server/                       # Backend Dart
│   ├── bin/server.dart           # Point d'entrée
│   └── lib/                      # Database, handlers, router
├── test/
│   ├── unit/                     # Tests unitaires (mocks)
│   ├── integration/              # Tests intégration (vraie BDD)
│   └── acceptance/               # Tests acceptation (Gherkin/BDD)
├── integration_test/             # Tests système (E2E)
├── docker-compose.yml            # Dev local
├── Dockerfile                    # Build production
└── .github/workflows/ci.yml     # Pipeline CI/CD
```
