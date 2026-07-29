---
name: refactor-proposal
description: Analyser une zone de code des dépôts SMT et produire une proposition de refactoring argumentée, sans modifier le code. Lecture seule.
model: opus
---

# refactor-proposal

Propose des refactorings sur le code de `repos/`. Lecture seule stricte : ne modifie aucun fichier, ne commite pas. Sortie = proposition dans le chat.

## Quand l'utiliser
- `/refactor-proposal <zone : chemin, module, ou description>`.

## Prérequis
- Dépôts présents dans `repos/`. S'ils sont vides, le signaler.

## Étapes
1. Déléguer au sous-agent `code-explorer` la lecture de la zone visée (structure, dépendances, points chauds).
2. Identifier les problèmes : duplication, complexité, couplage, incohérences avec la spec (si pertinent), risques.
3. Pour chaque proposition : problème, changement proposé, bénéfice, risque / effort, extrait avant/après (illustratif, non appliqué).
4. Rester factuel : citer `fichier:ligne`. Pas de réécriture spéculative non justifiée (simplicité d'abord).

## Format de sortie (français, dans le chat)
- Liste priorisée (fort impact / faible risque d'abord).
- Pour chaque : justification + preuve code + esquisse.
- Rappel : aucune modification n'est appliquée (périmètre lecture seule) ; l'implémentation se fait par un dev, hors de cet assistant.
