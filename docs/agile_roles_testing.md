# Rôles Agile et Responsabilités de Tests

## Vue d'ensemble

Dans une équipe agile, la qualité est une responsabilité partagée. Chaque rôle contribue à la stratégie de tests à différents niveaux.

---

## Matrice des Responsabilités

| Niveau de Test | Responsable Principal | Contributeurs | Outils |
|---|---|---|---|
| **Tests Unitaires** | Développeur | - | `flutter_test`, `mockito` |
| **Tests d'Intégration** | Développeur | QA | `dart test`, PostgreSQL |
| **Tests Système (E2E)** | QA / Testeur | Développeur | `integration_test` |
| **Tests d'Acceptation** | Product Owner | QA, Développeur | Gherkin (`.feature`), `bdd_widget_test` |

---

## Détail par Rôle

### 🔧 Développeur

**Responsabilités :**
- Écrire les **tests unitaires** pour chaque nouveau code (modèles, services, handlers)
- Écrire les **tests d'intégration** pour vérifier les interactions entre composants (API + BDD)
- Pratiquer le **TDD** (Test-Driven Development) quand approprié
- Maintenir une **couverture de code > 80%**
- Corriger les tests cassés avant de merger une PR

**Quand :**
- À chaque user story / tâche technique
- Avant chaque Pull Request

**Artefacts produits :**
- Fichiers `test/unit/*.dart`
- Fichiers `test/integration/*.dart`
- Rapport de couverture (`coverage/lcov.info`)

---

### 🧪 QA / Testeur

**Responsabilités :**
- Concevoir le **cahier de recette** (test plan)
- Écrire les **tests système (E2E)** qui valident les flux complets
- Implémenter les **step definitions** des tests d'acceptation BDD
- Identifier les **cas limites** et **scénarios d'erreur**
- Exécuter les **tests de régression** avant chaque release
- Rapporter et suivre les **bugs**

**Quand :**
- En début de sprint : rédaction du cahier de recette
- En cours de sprint : écriture des tests E2E
- En fin de sprint : exécution de la recette complète

**Artefacts produits :**
- `docs/test_plan.md` (cahier de recette)
- Fichiers `integration_test/*.dart`
- Fichiers `test/acceptance/step_definitions/*.dart`
- Rapports de bugs

---

### 📋 Product Owner (PO)

**Responsabilités :**
- Définir les **critères d'acceptation** de chaque user story
- Rédiger les scénarios **Gherkin** (Given/When/Then) dans les fichiers `.feature`
- **Valider** les résultats des tests d'acceptation
- **Signer** le cahier de recette (acceptation formelle)

**Quand :**
- Lors du refinement / grooming : rédaction des critères d'acceptation
- En fin de sprint : validation des tests d'acceptation

**Artefacts produits :**
- Fichiers `test/acceptance/features/*.feature`
- Validation du cahier de recette

**Exemple de scénario Gherkin rédigé par le PO :**
```gherkin
Feature: Create a todo
  As a user
  I want to create a new todo item
  So that I can track my tasks

  Scenario: Create a simple todo
    Given I am on the todo list page
    And the list is empty
    When I tap the add button
    And I enter "Buy groceries" as the title
    And I tap save
    Then I should see "Buy groceries" in the todo list
```

---

### ⚙️ DevOps

**Responsabilités :**
- Configurer et maintenir le **pipeline CI/CD** (GitHub Actions)
- S'assurer que **tous les niveaux de tests** s'exécutent automatiquement
- Gérer les **environnements** (dev, test, staging, production)
- Configurer le **déploiement automatique** (Dokploy webhook)
- Monitorer les **tests flaky** (instables) et alerter l'équipe

**Quand :**
- En début de projet : mise en place du pipeline
- En continu : maintenance et optimisation du CI/CD

**Artefacts produits :**
- `.github/workflows/ci.yml`
- `Dockerfile`, `docker-compose.yml`
- Configuration Dokploy

---

## Flux de travail typique d'un Sprint

```
1. REFINEMENT (PO + Équipe)
   └─ PO rédige les critères d'acceptation (.feature)

2. DÉVELOPPEMENT (Développeur)
   ├─ Écrit le code
   ├─ Écrit les tests unitaires
   └─ Écrit les tests d'intégration

3. REVIEW (Développeur + QA)
   ├─ Code review de la PR
   ├─ Vérification des tests
   └─ Pipeline CI passe au vert ✅

4. RECETTE (QA + PO)
   ├─ QA exécute les tests système
   ├─ QA exécute les tests d'acceptation
   ├─ PO valide les résultats
   └─ Signature du cahier de recette

5. DÉPLOIEMENT (DevOps / Automatique)
   ├─ Merge sur main
   ├─ Pipeline CI complet
   └─ Webhook → Dokploy → Production
```

---

## Pyramide des Tests

```
        /\
       /  \        Tests d'Acceptation (PO)
      / AT \       → Peu nombreux, valident les user stories
     /------\
    /        \     Tests Système / E2E (QA)
   /  System  \    → Flux complets, coûteux en temps
  /------------\
 /              \  Tests d'Intégration (Dev + QA)
/ Integration   \  → Composants réels connectés
/----------------\
|                |  Tests Unitaires (Dev)
|     Unit       |  → Nombreux, rapides, isolés
|________________|
```

**Principe** : Plus on monte dans la pyramide, moins il y a de tests mais plus ils sont proches du comportement réel de l'utilisateur.
