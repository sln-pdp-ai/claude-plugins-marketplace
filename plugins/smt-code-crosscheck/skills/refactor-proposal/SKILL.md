---
name: refactor-proposal
description: Analyser une zone de code SMT et produire une proposition de refactoring argumentée (problème, changement, bénéfice, risque, effort), sans modifier le code. Lecture seule.
model: opus
---

# refactor-proposal

Propose des refactorings sur le code SMT. Lecture seule stricte : ne modifie aucun fichier, ne commite
pas. Sortie = proposition dans le chat.

## Quand l'utiliser
- `/smt-code-crosscheck:refactor-proposal <zone : chemin, module, ou description>`.

## Prérequis
1. Lire le skill `policy` de ce plugin.
2. Localiser et valider les dépôts de code :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need code
```

   Verdict autre que `A_JOUR` : s'arrêter. Proposer un refactoring sur du code déjà réécrit fait perdre
   du temps au dev.
3. Si la comparaison avec la spec est utile, ajouter le corpus (`-Need all`).

## Étapes
1. Déléguer au sous-agent `code-explorer` la lecture de la zone visée (structure, dépendances, points
   chauds), en lui transmettant les chemins résolus.
2. Identifier les problèmes : duplication, complexité, couplage, incohérences avec la spec (si
   pertinent), risques.
3. Pour chaque proposition : problème, changement proposé, bénéfice, risque / effort, extrait
   avant/après (illustratif, non appliqué).
4. Rester factuel : citer `fichier:ligne`. Pas de réécriture spéculative non justifiée (simplicité
   d'abord).

## Format de sortie (français, dans le chat)
- Liste priorisée (fort impact / faible risque d'abord).
- Pour chaque : justification + preuve code + esquisse.
- Rappel : aucune modification n'est appliquée. L'implémentation se fait par un dev.
