# Cahier de Recette — Application Todo List

## 1. Informations Générales

| Champ | Valeur |
|---|---|
| **Projet** | Todo List (Flutter Web) |
| **Version** | 0.1.0 |
| **Date** | 2026-03-17 |
| **Rédacteur** | QA / Testeur |
| **Validateur** | Product Owner |

---

## 2. Périmètre

### Fonctionnalités testées
- Créer un todo (titre + description optionnelle)
- Lister les todos
- Marquer un todo comme terminé / non terminé
- Supprimer un todo
- Filtrer les todos (Tous / Actifs / Terminés)

### Hors périmètre
- Authentification utilisateur
- Multi-utilisateurs
- Notifications

---

## 3. Environnements de Test

| Environnement | Description | Base de données |
|---|---|---|
| **Local** | `docker-compose up` | PostgreSQL locale (conteneur) |
| **CI** | GitHub Actions | PostgreSQL service (conteneur éphémère) |
| **Staging** | Dokploy (auto-deploy depuis `main`) | PostgreSQL Dokploy |

---

## 4. Critères d'Entrée

- [ ] Le code compile sans erreur (`flutter analyze` + `dart analyze`)
- [ ] La base de données est accessible
- [ ] Les dépendances sont installées (`flutter pub get`, `dart pub get`)
- [ ] Le pipeline CI est fonctionnel

## 5. Critères de Sortie

- [ ] 100% des tests d'acceptation passent
- [ ] 100% des tests système passent
- [ ] 100% des tests d'intégration passent
- [ ] Couverture de code > 80% sur `lib/`
- [ ] 0 bug critique ou bloquant ouvert
- [ ] Validation du Product Owner

---

## 6. Scénarios de Test

### 6.1 Tests Unitaires (TU)

| ID | Composant | Scénario | Résultat Attendu | Statut |
|---|---|---|---|---|
| TU-01 | Todo Model | `fromJson` avec JSON valide | Objet Todo créé correctement | ⬜ |
| TU-02 | Todo Model | `fromJson` avec description null | `description` est null | ⬜ |
| TU-03 | Todo Model | `toJson` produit un map correct | Toutes les clés présentes | ⬜ |
| TU-04 | Todo Model | `copyWith` change isCompleted | Autres champs inchangés | ⬜ |
| TU-05 | Todo Model | Égalité entre deux todos identiques | `==` retourne true | ⬜ |
| TU-06 | ApiTodoRepository | `getAll` retourne la liste sur 200 | Liste de todos parsée | ⬜ |
| TU-07 | ApiTodoRepository | `getAll` lance exception sur 500 | Exception levée | ⬜ |
| TU-08 | ApiTodoRepository | `create` envoie POST correct | Todo créé retourné | ⬜ |
| TU-09 | ApiTodoRepository | `delete` réussit sur 204 | Pas d'exception | ⬜ |
| TU-10 | TodoHandler | `getAll` retourne [] si vide | Status 200, body [] | ⬜ |
| TU-11 | TodoHandler | `create` sans titre | Status 400, erreur | ⬜ |
| TU-12 | TodoHandler | `create` avec titre valide | Status 201, todo créé | ⬜ |
| TU-13 | TodoHandler | `getById` todo inexistant | Status 404 | ⬜ |
| TU-14 | TodoHandler | `delete` todo existant | Status 204 | ⬜ |
| TU-15 | TodoHandler | `update` marquer comme terminé | Status 200, is_completed=true | ⬜ |

### 6.2 Tests d'Intégration (TI)

| ID | Composant | Scénario | Résultat Attendu | Statut |
|---|---|---|---|---|
| TI-01 | DB Repository | Créer et récupérer un todo | Todo en BDD identique | ⬜ |
| TI-02 | DB Repository | Créer avec description | Description stockée | ⬜ |
| TI-03 | DB Repository | `getAll` ordre chronologique DESC | Plus récent en premier | ⬜ |
| TI-04 | DB Repository | Update isCompleted | Champ mis à jour en BDD | ⬜ |
| TI-05 | DB Repository | Delete supprime le todo | `getById` lance NotFoundException | ⬜ |
| TI-06 | DB Repository | `getById` id inexistant | NotFoundException | ⬜ |
| TI-07 | API + DB | `GET /api/health` | Status 200, `{"status":"ok"}` | ⬜ |
| TI-08 | API + DB | Flux CRUD complet via HTTP | Create→Read→Update→Delete OK | ⬜ |
| TI-09 | API + DB | `POST /api/todos` sans titre | Status 400 | ⬜ |
| TI-10 | API + DB | `GET /api/todos/:id` inexistant | Status 404 | ⬜ |

### 6.3 Tests Système (TS)

| ID | Scénario | Étapes | Résultat Attendu | Statut |
|---|---|---|---|---|
| TS-01 | Flux CRUD complet | 1. App démarre<br>2. Vérifier état vide<br>3. Créer un todo<br>4. Vérifier affichage<br>5. Compléter le todo<br>6. Supprimer le todo<br>7. Vérifier état vide | Chaque étape réussie | ⬜ |
| TS-02 | Filtrage des todos | 1. Créer 1 actif + 1 terminé<br>2. Filtre "All" → 2 visibles<br>3. Filtre "Active" → 1 visible<br>4. Filtre "Completed" → 1 visible | Filtres fonctionnels | ⬜ |

### 6.4 Tests d'Acceptation (TA)

| ID | Feature | Scénario | Critère d'Acceptation | Statut |
|---|---|---|---|---|
| TA-01 | Create Todo | Créer un todo simple | Le todo apparaît dans la liste | ⬜ |
| TA-02 | Create Todo | Titre vide | Message d'erreur "Title is required" | ⬜ |
| TA-03 | Complete Todo | Marquer comme terminé | Le todo est barré (line-through) | ⬜ |
| TA-04 | Delete Todo | Supprimer un todo | Le todo disparaît de la liste | ⬜ |

---

## 7. Suivi d'Exécution

### Résumé

| Niveau | Total | ✅ Passés | ❌ Échoués | ⬜ Non exécutés |
|---|---|---|---|---|
| Unitaires | 15 | 0 | 0 | 15 |
| Intégration | 10 | 0 | 0 | 10 |
| Système | 2 | 0 | 0 | 2 |
| Acceptation | 4 | 0 | 0 | 4 |
| **Total** | **31** | **0** | **0** | **31** |

### Couverture de code
- Objectif : > 80%
- Résultat : _à compléter_

---

## 8. Anomalies Détectées

| ID | Sévérité | Description | Statut | Assigné à |
|---|---|---|---|---|
| _Aucune_ | | | | |

---

## 9. Signatures

| Rôle | Nom | Date | Signature |
|---|---|---|---|
| QA / Testeur | | | |
| Product Owner | | | |
| Tech Lead | | | |
