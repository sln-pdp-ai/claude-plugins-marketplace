---
name: doc-freshness
description: Comparer un fichier de spec du dépôt sln-smt-spec-owner au code actuel des dépôts SMT et lister ce qui est périmé. Propose des corrections sans les appliquer. Lecture seule.
model: sonnet
---

# doc-freshness

Vérifie qu'un fichier de spec reflète encore le code. Lecture seule : propose, n'écrit rien (ni fichier,
ni Confluence).

## Quand l'utiliser
- `/doc-freshness <chemin d'un fichier de spec>` (optionnellement une zone de code cible).
- Différence avec `spec-vs-code` : là, on part de la spec comme référence et on juge le code ; ici, on
  part du code comme réalité constatée et on juge ce que la spec dit encore de vrai. À utiliser quand
  la spec est susceptible d'avoir pris du retard sur une implémentation déjà faite.

## Prérequis
- Cible : un fichier de `repos/sln-smt-spec-owner/`. Ce skill ne parle pas à Confluence : les pages
  Confluence sont une livraison synthétique produite par un autre projet, hors périmètre ici (voir
  CLAUDE.md). Si on lui donne une URL Confluence, le dire et demander le chemin du fichier
  correspondant.
- Dépôts de code présents dans `repos/`. S'ils sont vides, le signaler (rien à comparer).
- **Clones à jour** : appliquer le contrôle de fraîcheur de CLAUDE.md (« Fraîcheur des clones ») sur les
  trois dépôts avant l'étape 2. Ce skill mesure la péremption d'une spec : le faire depuis un clone
  périmé produirait l'erreur exacte qu'il cherche à détecter. En retard, `fetch` impossible ou working
  tree non vide : s'arrêter et le signaler.

## Étapes
1. Charger le fichier de spec et repérer ses affirmations vérifiables dans le code (entités, propriétés,
   statuts, règles, endpoints, flux, noms techniques, configs).
2. Déléguer au sous-agent `code-explorer` la recherche des éléments correspondants dans `repos/`.
3. Pour chaque affirmation : À JOUR / PÉRIMÉ / INTROUVABLE, avec `fichier:ligne` des deux côtés.
4. Rédiger une proposition de correction pour chaque écart (texte prêt à coller dans le markdown de la
   spec), sans l'appliquer.
5. Résoudre le vocabulaire via `solution-overview/glossary.md` ; fail-fast si un terme bloque.
6. Ne pas confondre « périmé » et « pas encore implémenté » : une règle spécifiée et absente du code est
   un manque côté code (ressort de `spec-vs-code`), pas une spec périmée. Ce skill ne signale comme
   PÉRIMÉ que ce que le code contredit.

## Format de sortie (français, dans le chat)
- Tableau : Affirmation (citée, `fichier:ligne`) | Statut | Preuve code | Correction proposée.
- Rappel : ce skill n'applique jamais ses corrections. Le corpus de specs est en lecture seule ici, son
  évolution appartient au projet du PO.
