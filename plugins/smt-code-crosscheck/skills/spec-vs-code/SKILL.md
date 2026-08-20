---
name: spec-vs-code
description: Comparer une spec SMT (fichier du corpus de specs ou story Jira) au code réellement présent dans sln-smt-backend et sln-smt-console, et lister les écarts. Chaque règle notée IMPLÉMENTÉ / PARTIEL / ABSENT / DIVERGENT, les deux côtés cités. Lecture seule.
model: opus
---

# spec-vs-code

Recoupe une spec avec le code réel. Lecture seule : rapport dans le chat, aucune écriture, aucun commit.

## Quand l'utiliser
- `/smt-code-crosscheck:spec-vs-code <fichier de spec | clé Jira>` pour vérifier « le code fait-il ce
  que dit la spec ».

## Prérequis
1. Lire le skill `policy` de ce plugin : doctrine, conventions du corpus, résolution des dépôts.
2. Localiser et valider les trois dépôts :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need all
```

   Verdict autre que `A_JOUR` : s'arrêter et appliquer l'interprétation fail-fast du skill `policy`. Un
   dépôt en retard invalide la comparaison des deux côtés, avec des citations qui ont l'air sourcées.
3. Si les dépôts de code sont présents mais vides ou quasi vides (stade « Initial commit »), le dire
   franchement : il n'y a rien à recouper, et s'arrêter.

## Étapes
1. Charger la spec depuis le corpus et la story / epic Jira liée (MCP). Résoudre le vocabulaire via
   `solution-overview/glossary.md`. Si la cible est une slice `SMT-VS-NN`, remonter aux exigences EARS
   qu'elle référence : la règle normative est là, pas dans la slice.
2. Extraire les règles vérifiables (comportements, contraintes, contrats), chacune avec son identifiant
   EARS. Distinguer les règles **Integrity** (toujours vraies, jamais levées par un Override) des règles
   **Lifecycle** (conditionnées par le statut) : une règle Integrity implémentée comme conditionnelle est
   un écart, même si le cas nominal passe.
3. Déléguer au sous-agent `code-explorer` (lecture seule). Lui transmettre **les chemins résolus** des
   deux dépôts de code, jamais un chemin supposé, et les règles à chercher. Demander une synthèse
   « règle : présence / absence dans le code, avec fichier:ligne ».
4. Confronter : pour chaque règle, IMPLÉMENTÉ / PARTIEL / ABSENT / DIVERGENT.
5. Fail-fast : si la spec est ambiguë au point de rendre la comparaison impossible, ou si une question
   ouverte `SMT-<MODULE>-OQ-<NN>` porte sur la règle comparée, s'arrêter et le signaler. Ne pas arbitrer
   à la place du spec owner en se fondant sur ce que fait le code.
6. Écarter du périmètre ce que `functional-specifications/post-mvp-out-of-golive-scope.md` déclare hors
   MVP : une règle post-MVP absente du code n'est pas un écart.

## Format de sortie (français, dans le chat)
- Tableau : Règle (réf. EARS + `fichier:ligne` de la spec) | Statut | Preuve code (`fichier:ligne`) | Écart.
- Synthèse des divergences et des zones non couvertes.
- Toujours citer les deux côtés. Ne rien affirmer sans preuve.
