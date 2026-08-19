---
name: spec-readiness
description: Évaluer si une spec fonctionnelle (fichier du dépôt de specs ou epic/story Jira) est assez claire, complète et cohérente pour être développée. Check-list fail-fast. Lecture seule.
model: sonnet
---

# spec-readiness

Revue « prêt pour le dev » d'une spec, dans l'esprit fail-fast de CLAUDE.md. Lecture seule : rapport
dans le chat, aucune écriture.

## Quand l'utiliser
- `/spec-readiness <fichier de spec | epic ou story Jira>` avant d'estimer ou de lancer un dev.

## Prérequis
- Les specs sont dans `repos/sln-smt-spec-owner/solution-overview/`. Dépôt absent : STOP, indiquer
  `.\scripts\bootstrap.ps1`.
- **Clone à jour** : appliquer le contrôle de fraîcheur de CLAUDE.md (« Fraîcheur des clones ») sur
  `sln-smt-spec-owner` avant l'étape 1. Juger « prête » une spec révisée depuis est exactement l'erreur
  que ce skill est censé éviter. En retard, `fetch` impossible ou working tree non vide : s'arrêter et
  le signaler.

## Étapes
1. Charger la spec depuis le dépôt de specs (Read) et l'epic / les stories Jira liées (MCP). Si la
   cible est une slice `SMT-VS-NN`, remonter aux exigences EARS qu'elle référence : une slice ne
   recopie jamais le texte de la règle.
2. Contrôle terminologique (logique de `term-check`) : résoudre les termes contre
   `solution-overview/glossary.md`. Signaler les termes au statut 🔴 ou ⚪ quand ils portent la règle
   évaluée.
3. Passer la check-list :
   - Objectif et périmètre explicites.
   - Acteurs / déclencheurs / préconditions clairs.
   - Règles de gestion sans ambiguïté ni contradiction (interne, vs Jira, vs glossaire).
   - Chaque règle porte un identifiant EARS `SMT-<MODULE>-<NNN>` et est formulée de façon vérifiable.
   - Nature de chaque règle tranchée : **Integrity** (jamais levée, même par Override) ou
     **Lifecycle** (dépend du statut, levable par Override Admin). Une règle dont la famille n'est pas
     tranchée est ambiguë.
   - Critères d'acceptation vérifiables.
   - Cas limites et cas d'erreur traités.
   - Dépendances externes identifiées.
   - Aucun « TODO », « à confirmer » ou placeholder non résolu.
4. Chaque point : OK / MANQUE / AMBIGU / CONTRADICTION, avec citation précise (`fichier:ligne` +
   identifiant EARS, clé Jira).
5. Traiter les questions ouvertes comme des manques, jamais comme des réponses : toute
   `SMT-<MODULE>-OQ-<NN>` qui porte sur le périmètre évalué est bloquante, y compris quand elle est
   seulement référencée par la page (elles sont centralisées dans
   `functional-specifications/overall-questions.md` et dans chaque page de module). Idem pour tout
   « à confirmer », « TBC » ou « to be discussed » rencontré dans le texte.
6. Vérifier que le périmètre visé n'est pas listé dans
   `functional-specifications/post-mvp-out-of-golive-scope.md` : le cas échéant, le dire d'emblée, la
   question de la readiness ne se pose pas de la même façon.

## Format de sortie (français, dans le chat)
- Verdict : PRÊT / PAS PRÊT.
- Tableau des points avec statut et citation.
- Section « Bloquants (fail-fast) » : ce qui doit être levé, et la question précise à poser.
- Ne jamais combler un manque par une hypothèse : le signaler.
- Les corrections proposées restent des propositions : le corpus de specs est en lecture seule ici,
  son évolution appartient au projet du PO.
