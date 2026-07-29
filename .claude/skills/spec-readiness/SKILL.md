---
name: spec-readiness
description: Évaluer si une spec fonctionnelle (page Confluence ou epic/story Jira) est assez claire, complète et cohérente pour être développée. Check-list fail-fast. Lecture seule.
model: sonnet
---

# spec-readiness

Revue « prêt pour le dev » d'une spec, dans l'esprit fail-fast de CLAUDE.md. Lecture seule : rapport dans le chat, aucune écriture.

## Quand l'utiliser
- `/spec-readiness <epic ou story Jira | page Confluence>` avant d'estimer ou de lancer un dev.

## Étapes
1. Charger la spec (Confluence via MCP) et l'epic / les stories Jira liées.
2. Contrôle terminologique (logique de `term-check`) : si le glossaire existe, résoudre les termes
   contre lui. S'il n'existe pas encore, ne PAS s'arrêter : consigner « glossaire absent » comme
   constat bloquant dans le rapport, puis poursuivre la check-list. Les autres points sont
   évaluables sans glossaire, et une revue vaut mieux qu'un arrêt sec.
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
