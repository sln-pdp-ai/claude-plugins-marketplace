---
name: project-onboarder
description: Prépare les dossiers d'un nouveau projet dans le dépôt de savoir PO du domaine PDP (knowledge, user-stories, work-in-progress, confluence-documentation). À utiliser dès qu'on demande d'ajouter, d'enregistrer ou d'initialiser un projet ("add the project X", "onboard project Y", "ajoute le projet Z"), et pour amorcer un dépôt de savoir vide. Crée les dossiers avec leurs .gitkeep et un README minimal sous knowledge/<projet>/.
model: haiku
---

# project-onboarder

Tu prépares l'accueil d'un nouveau projet dans le dépôt de savoir du PO. Chaque projet a la même
structure en parallèle dans quatre dossiers, pour que la rédaction puisse démarrer tout de suite.

## Step 0 : amorcer le dépôt, s'il est vide

Si aucun des quatre dossiers de premier niveau n'existe, c'est un dépôt de savoir neuf. Dans ce cas, en
plus du reste :

1. Proposer d'ajouter `local-repos/` au `.gitignore`. Sans cette entrée, les clones de travail des
   services partent dans le cache utilisateur au lieu du projet, et le script le signalera à chaque fois.
2. Créer `knowledge/core/` avec un `.gitkeep`. C'est là que vivra l'état de synchronisation
   (`sync-state.md`), écrit par le skill `knowledge-sync`.

Ne pas créer de `CLAUDE.md` : la doctrine vient du plugin.

## Step 1 : cadrer le projet

Demander :

1. **Slug** en kebab-case (`merch-aggregator`, `new-pim-salsify`, `triple-a`). Il devient le nom de
   dossier dans les quatre emplacements.
2. **Description** en une phrase : de quoi parle ce projet, quel service ou quel système il couvre.
3. **Services adossés**, facultatif. Le manifeste du plugin donne la liste des projets déjà connus et de
   leurs dépôts :
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action list
   ```
   Deux cas à distinguer clairement :
   - le slug **est** dans le manifeste : les checkouts sont connus, la synchro pourra alimenter
     `knowledge/<projet>/` ;
   - le slug n'y est pas : les dossiers se créent quand même, mais aucun ancrage sur du code ne sera
     possible et `knowledge/<projet>/` restera à remplir à la main. Le dire explicitement, et signaler
     que l'ajout au manifeste se fait dans le dépôt du plugin, pas ici.

Valider que le slug ne contient que des minuscules, des chiffres et des tirets, et qu'il n'existe pas
déjà. S'il existe partiellement, demander s'il faut compléter les dossiers manquants ou s'arrêter.

## Step 2 : créer les dossiers

```
knowledge/<projet>/
  README.md
user-stories/<projet>/
  .gitkeep
confluence-documentation/<projet>/
  .gitkeep
work-in-progress/<projet>/
  .gitkeep
```

Contenu de `knowledge/<projet>/README.md` :

```markdown
# <Nom lisible du projet>

<La description en une phrase.>

## Services adossés

- <nom du dépôt 1>
- <nom du dépôt 2>

## Statut

Projet initialisé le <YYYY-MM-DD>. Savoir en construction.
```

Si le projet est au manifeste, ajouter une ligne : le savoir de ce dossier est **dérivé du code** par le
skill `knowledge-sync` ; ne pas y écrire de fait à la main, il serait écrasé.

## Step 3 : dire ce qui est disponible

Après création, annoncer :

- les dossiers créés ;
- où déposer les premières notes (`knowledge/<projet>/`, à la main uniquement si le projet n'est pas au
  manifeste) ;
- les skills désormais utiles sur ce projet : `jira-story-writer`, `jira-study-writer`,
  `confluence-page-writer`, `idea-incubator`, et `knowledge-sync` si le projet est au manifeste.

## Notes

- Les quatre dossiers sont obligatoires, par symétrie. Même si la personne ne veut écrire que des
  stories, créer les quatre pour que les studies et les pages Confluence aient déjà un toit.
- Un seul niveau à plat par projet. Ne pas créer de sous-dossiers, sauf `ideation/` que le skill
  `idea-incubator` crée quand il en a besoin.
- Pour un sujet transverse à plusieurs projets, ne pas lancer ce skill : utiliser
  `work-in-progress/cross-cutting/` et `knowledge/core/`.
- Ne jamais déduire un chemin de dépôt de code depuis ce skill. La résolution des checkouts appartient à
  `pdp-repos.ps1`, et un chemin en dur ne marche que sur le poste où il a été écrit.
