---
name: doc-freshness
description: Comparer un fichier de spec SMT au code actuel et lister ce que le code contredit. Part du code comme réalité constatée et juge ce que la spec dit encore de vrai. Propose des corrections sans les appliquer. Lecture seule.
model: sonnet
---

# doc-freshness

Vérifie qu'un fichier de spec reflète encore le code. Lecture seule : propose, n'écrit rien.

## Quand l'utiliser
- `/smt-code-crosscheck:doc-freshness <chemin d'un fichier de spec>` (optionnellement une zone de code
  cible).
- Différence avec `spec-vs-code` : là, on part de la spec comme référence et on juge le code ; ici, on
  part du code comme réalité constatée et on juge ce que la spec dit encore de vrai. À utiliser quand la
  spec est susceptible d'avoir pris du retard sur une implémentation déjà faite.

## Prérequis
1. Lire le skill `policy` de ce plugin.
2. Localiser et valider les trois dépôts :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need all
```

   Verdict autre que `A_JOUR` : s'arrêter. Ce skill mesure la péremption d'une spec : le faire depuis un
   clone périmé produirait l'erreur exacte qu'il cherche à détecter.
3. Cible : un fichier du corpus de specs. Ce skill ne parle pas à Confluence, dont les pages sont une
   livraison synthétique produite par un autre projet. Si on lui donne une URL Confluence, le dire et
   demander le chemin du fichier correspondant.

## Étapes
1. Charger le fichier de spec et repérer ses affirmations vérifiables dans le code (entités, propriétés,
   statuts, règles, endpoints, flux, noms techniques, configs).
2. Déléguer au sous-agent `code-explorer` la recherche des éléments correspondants, en lui transmettant
   les chemins résolus des dépôts de code.
3. Pour chaque affirmation : À JOUR / PÉRIMÉ / INTROUVABLE, avec `fichier:ligne` des deux côtés.
4. Rédiger une proposition de correction pour chaque écart (texte prêt à coller dans le markdown de la
   spec), sans l'appliquer.
5. Résoudre le vocabulaire via `solution-overview/glossary.md` ; fail-fast si un terme bloque.
6. Ne pas confondre « périmé » et « pas encore implémenté » : une règle spécifiée et absente du code est
   un manque côté code (ressort de `spec-vs-code`), pas une spec périmée. Ne signaler comme PÉRIMÉ que
   ce que le code contredit.

## Format de sortie (français, dans le chat)
- Tableau : Affirmation (citée, `fichier:ligne`) | Statut | Preuve code | Correction proposée.
- Rappel : aucune correction n'est appliquée. L'évolution du corpus appartient à son propriétaire.
