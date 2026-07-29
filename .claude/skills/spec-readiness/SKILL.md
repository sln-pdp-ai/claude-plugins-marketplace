---
name: spec-readiness
description: Évaluer si une spec fonctionnelle (page Confluence ou epic/story Jira) est assez claire, complète et cohérente pour être développée. Check-list fail-fast. Lecture seule.
model: sonnet
---

# spec-readiness

Revue « prêt pour le dev » d'une spec, dans l'esprit fail-fast de CLAUDE.md. Lecture seule : rapport dans le chat, aucune écriture.

## Quand l'utiliser
- `/spec-review <epic ou story Jira | page Confluence>` avant d'estimer ou de lancer un dev.

## Étapes
1. Charger la spec (Confluence via MCP) et l'epic / les stories Jira liées.
2. Appliquer la logique de `term-check` (cohérence terminologique vs glossaire).
3. Passer la check-list :
   - Objectif et périmètre explicites.
   - Acteurs / déclencheurs / préconditions clairs.
   - Règles de gestion sans ambiguïté ni contradiction (interne, vs Jira, vs glossaire).
   - Critères d'acceptation vérifiables.
   - Cas limites et cas d'erreur traités.
   - Dépendances externes identifiées.
   - Aucun « TODO », « à confirmer » ou placeholder non résolu.
4. Chaque point : OK / MANQUE / AMBIGU / CONTRADICTION, avec citation précise (page + section, clé Jira).

## Format de sortie (français, dans le chat)
- Verdict : PRÊT / PAS PRÊT.
- Tableau des points avec statut et citation.
- Section « Bloquants (fail-fast) » : ce qui doit être levé, et la question précise à poser.
- Ne jamais combler un manque par une hypothèse : le signaler.
