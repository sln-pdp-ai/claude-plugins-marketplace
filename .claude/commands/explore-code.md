---
description: Explorer le code des dépôts SMT en lecture seule via le sous-agent code-explorer
argument-hint: <question ou zone de code à explorer>
---

Délègue immédiatement l'exploration au sous-agent `code-explorer` (lecture seule) via l'outil Agent,
avec `subagent_type: code-explorer`.

Brief à lui transmettre : $ARGUMENTS

Si aucun argument n'est fourni, demander d'abord ce qu'il faut explorer plutôt que de lancer un
balayage au hasard.

Consignes :
- Périmètre : uniquement `repos/sln-smt-backend/` et `repos/sln-smt-console/`.
- Exiger du sous-agent des constats étayés par `fichier:ligne`.
- Restituer sa synthèse telle quelle, sans la compléter par des suppositions.
- Si les dépôts sont vides ou la zone introuvable, le signaler franchement (fail-fast) au lieu
  d'extrapoler.
- Aucune écriture, aucun commit : le sous-agent n'a que Read, Grep et Glob.
