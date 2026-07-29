---
name: doc-freshness
description: Comparer une page de documentation Confluence au code actuel des dépôts SMT et lister ce qui est périmé. Propose des corrections sans les appliquer. Lecture seule.
model: sonnet
---

# doc-freshness

Vérifie qu'une page Confluence reflète encore le code. Lecture seule : propose, n'écrit rien (ni Confluence, ni fichiers).

## Quand l'utiliser
- `/doc-refresh <page Confluence>` (optionnellement une zone de code cible).

## Prérequis
- Dépôts présents dans `repos/`. S'ils sont vides, le signaler (rien à comparer).

## Étapes
1. Charger la page Confluence (MCP) et repérer ses affirmations vérifiables (endpoints, flux, noms, configs).
2. Déléguer au sous-agent `code-explorer` la recherche des éléments correspondants dans `repos/`.
3. Pour chaque affirmation : À JOUR / PÉRIMÉ / INTROUVABLE, avec `fichier:ligne`.
4. Rédiger une proposition de correction pour chaque écart (texte prêt à coller), sans l'appliquer.
5. Résoudre le vocabulaire via le glossaire ; fail-fast si un terme bloque.

## Format de sortie (français, dans le chat)
- Tableau : Affirmation (citée) | Statut | Preuve code | Correction proposée.
- Rappel : l'application dans Confluence reste manuelle (périmètre lecture seule).
