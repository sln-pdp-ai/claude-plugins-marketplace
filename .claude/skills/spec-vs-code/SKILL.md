---
name: spec-vs-code
description: Comparer une spec (Confluence/Jira) au code réellement présent dans les dépôts SMT et lister les écarts. Délègue l'exploration du code au sous-agent code-explorer. Lecture seule.
model: opus
---

# spec-vs-code

Recoupe une spec avec le code des dépôts clonés dans `repos/`. Lecture seule : rapport dans le chat, aucune écriture, aucun commit.

## Quand l'utiliser
- `/spec-vs-code <clé Jira | page Confluence>` pour vérifier « le code fait-il ce que dit la spec ».

## Prérequis
- Dépôts présents et remplis dans `repos/` (voir CLAUDE.md). S'ils sont vides ou quasi vides, le dire franchement : il n'y a rien à recouper, et s'arrêter (fail-fast).
- **Clones à jour** : appliquer le contrôle de fraîcheur de CLAUDE.md (« Fraîcheur des clones ») sur `sln-smt-backend` et `sln-smt-console` avant l'étape 3. Un clone en retard invalide la comparaison : le rapport conclurait sur du code qui n'existe plus. En retard, `fetch` impossible ou working tree non vide : s'arrêter et le signaler.

## Étapes
1. Charger la spec (Confluence via MCP) et la story / epic Jira liée. Résoudre le vocabulaire via le glossaire.
2. Extraire les règles vérifiables de la spec (comportements, contraintes, contrats).
3. Déléguer au sous-agent `code-explorer` (lecture seule) : lui donner les règles à chercher dans `repos/sln-smt-backend` et `repos/sln-smt-console`, et demander une synthèse « règle : présence / absence dans le code, avec fichier:ligne ».
4. Confronter : pour chaque règle : IMPLÉMENTÉ / PARTIEL / ABSENT / DIVERGENT.
5. Fail-fast : si la spec est ambiguë au point de rendre la comparaison impossible, s'arrêter et le signaler.

## Format de sortie (français, dans le chat)
- Tableau : Règle (spec, citée) | Statut | Preuve code (`fichier:ligne`) | Écart.
- Synthèse des divergences et des zones non couvertes.
- Toujours citer les deux côtés (spec + code). Ne rien affirmer sans preuve.
