---
name: spec-vs-code
description: Comparer une spec (fichier du dépôt de specs ou story Jira) au code réellement présent dans les dépôts SMT et lister les écarts. Délègue l'exploration du code au sous-agent code-explorer. Lecture seule.
model: opus
---

# spec-vs-code

Recoupe une spec avec le code des dépôts clonés dans `repos/`. Lecture seule : rapport dans le chat,
aucune écriture, aucun commit.

## Quand l'utiliser
- `/spec-vs-code <fichier de spec | clé Jira>` pour vérifier « le code fait-il ce que dit la spec ».

## Prérequis
- Trois dépôts présents et remplis dans `repos/` : `sln-smt-spec-owner` (la spec),
  `sln-smt-backend` et `sln-smt-console` (le code). Si les dépôts de code sont vides ou quasi vides, le
  dire franchement : il n'y a rien à recouper, et s'arrêter (fail-fast).
- **Clones à jour** : appliquer le contrôle de fraîcheur de CLAUDE.md (« Fraîcheur des clones ») sur
  les trois dépôts avant les étapes 1 et 3. Un clone en retard invalide la comparaison des deux côtés :
  spec périmée contre code périmé, avec des citations qui ont l'air sourcées. En retard, `fetch`
  impossible ou working tree non vide : s'arrêter et le signaler.

## Étapes
1. Charger la spec depuis `repos/sln-smt-spec-owner/solution-overview/` (Read) et la story / epic Jira
   liée (MCP). Résoudre le vocabulaire via `solution-overview/glossary.md`. Si la cible est une slice
   `SMT-VS-NN`, remonter aux exigences EARS qu'elle référence : la règle normative est là, pas dans la
   slice.
2. Extraire les règles vérifiables de la spec (comportements, contraintes, contrats), chacune avec son
   identifiant EARS `SMT-<MODULE>-<NNN>`. Distinguer les règles **Integrity** (toujours vraies, jamais
   levées par un Override) des règles **Lifecycle** (conditionnées par le statut) : une règle Integrity
   implémentée comme conditionnelle est un écart, même si le cas nominal passe.
3. Déléguer au sous-agent `code-explorer` (lecture seule) : lui donner les règles à chercher dans
   `repos/sln-smt-backend` et `repos/sln-smt-console`, et demander une synthèse « règle : présence /
   absence dans le code, avec fichier:ligne ».
4. Confronter : pour chaque règle : IMPLÉMENTÉ / PARTIEL / ABSENT / DIVERGENT.
5. Fail-fast : si la spec est ambiguë au point de rendre la comparaison impossible, ou si une question
   ouverte `SMT-<MODULE>-OQ-<NN>` porte sur la règle comparée, s'arrêter et le signaler. Ne pas
   arbitrer à la place du PO en se fondant sur ce que fait le code.
6. Écarter du périmètre ce que `functional-specifications/post-mvp-out-of-golive-scope.md` déclare hors
   MVP : une règle post-MVP absente du code n'est pas un écart.

## Format de sortie (français, dans le chat)
- Tableau : Règle (réf. EARS + `fichier:ligne` de la spec) | Statut | Preuve code (`fichier:ligne`) | Écart.
- Synthèse des divergences et des zones non couvertes.
- Toujours citer les deux côtés (spec + code). Ne rien affirmer sans preuve.
