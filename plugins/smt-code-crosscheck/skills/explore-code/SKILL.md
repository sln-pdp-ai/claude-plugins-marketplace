---
name: explore-code
description: Explorer le code SMT en lecture seule via le sous-agent code-explorer et rendre une synthèse sourcée en fichier:ligne. À utiliser pour localiser une implémentation ou cartographier une zone sans charger le code dans la conversation.
model: sonnet
---

# explore-code

Délègue l'exploration au sous-agent `code-explorer` (lecture seule) via l'outil Agent, avec
`subagent_type: code-explorer`.

Brief à lui transmettre : $ARGUMENTS

Si aucun argument n'est fourni, demander d'abord ce qu'il faut explorer plutôt que de lancer un balayage
au hasard.

## Prérequis
1. Lire le skill `policy` de ce plugin.
2. Localiser et valider les dépôts de code, et transmettre les chemins résolus au sous-agent :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need code
```

## Consignes
- Périmètre : uniquement les deux dépôts de code. Le corpus de specs n'est pas du code : si la question
  porte sur une règle spécifiée, lire la spec ici et transmettre la règle au sous-agent.
- Exiger du sous-agent des constats étayés par `fichier:ligne`.
- Restituer sa synthèse telle quelle, sans la compléter par des suppositions.
- Si les dépôts sont vides ou la zone introuvable, le signaler franchement (fail-fast) au lieu
  d'extrapoler.
- Aucune écriture, aucun commit : le sous-agent n'a que Read, Grep et Glob.
