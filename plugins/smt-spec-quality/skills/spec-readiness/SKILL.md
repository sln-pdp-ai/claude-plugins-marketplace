---
name: spec-readiness
description: Évaluer si une spec fonctionnelle SMT (fichier du corpus de specs ou epic/story Jira) est assez claire, complète et cohérente pour être développée. Check-list fail-fast, verdict PRÊT / PAS PRÊT. Lecture seule.
model: sonnet
---

# spec-readiness

Revue « prêt pour le dev » d'une spec, dans l'esprit fail-fast du skill `policy`. Lecture seule :
rapport dans le chat, aucune écriture.

## Quand l'utiliser
- `/smt-spec-quality:spec-readiness <fichier de spec | epic ou story Jira>` avant d'estimer ou de
  lancer un dev.

## Prérequis
1. Lire le skill `policy` de ce plugin.
2. Localiser et valider le corpus :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need spec
```

   Verdict autre que `A_JOUR` : s'arrêter. Juger « prête » une spec révisée depuis est exactement
   l'erreur que ce skill est censé éviter.

## Étapes
1. Charger la spec depuis le corpus (Read) et l'epic / les stories Jira liées (MCP). Si la cible est
   une slice `SMT-VS-NN`, remonter aux exigences EARS qu'elle référence : une slice ne recopie jamais
   le texte de la règle.
2. Contrôle terminologique (logique de `term-check`) : résoudre les termes contre
   `solution-overview/glossary.md`. Signaler les termes 🔴 ou ⚪ quand ils portent la règle évaluée.
3. Passer la check-list :
   - Objectif et périmètre explicites.
   - Acteurs / déclencheurs / préconditions clairs.
   - Règles de gestion sans ambiguïté ni contradiction (interne, vs Jira, vs glossaire).
   - Chaque règle porte un identifiant EARS `SMT-<MODULE>-<NNN>` et est formulée de façon vérifiable.
   - Nature de chaque règle tranchée : **Integrity** (jamais levée, même par Override) ou **Lifecycle**
     (dépend du statut, levable par Override Admin). Une règle dont la famille n'est pas tranchée est
     ambiguë.
   - Critères d'acceptation vérifiables.
   - Cas limites et cas d'erreur traités.
   - Dépendances externes identifiées.
   - Aucun « TODO », « à confirmer » ou placeholder non résolu.
4. Chaque point : OK / MANQUE / AMBIGU / CONTRADICTION, avec citation précise (`fichier:ligne` +
   identifiant EARS, clé Jira).
5. Traiter les questions ouvertes comme des manques, jamais comme des réponses : toute
   `SMT-<MODULE>-OQ-<NN>` qui porte sur le périmètre évalué est bloquante, y compris quand elle est
   seulement référencée. Idem pour tout « à confirmer », « TBC », « to be discussed ».
6. Vérifier que le périmètre visé n'est pas listé dans
   `functional-specifications/post-mvp-out-of-golive-scope.md` : le cas échéant, le dire d'emblée.

## Format de sortie (français, dans le chat)
- Verdict : PRÊT / PAS PRÊT.
- Tableau des points avec statut et citation.
- Section « Bloquants (fail-fast) » : ce qui doit être levé, et la question précise à poser.
- Ne jamais combler un manque par une hypothèse : le signaler.
- Les corrections proposées restent des propositions, portées par le propriétaire du corpus.
