---
name: jira-study-writer
description: Rédige une study (spike) Jira prête à coller, pour un projet du domaine PDP Salomon / Amer Sports. À utiliser dès qu'on demande de créer, rédiger ou générer une study ou un spike ("write a study on X", "fais une study", "spike pour evaluer Y", "compare ces options"). Produit un fichier Markdown sous work-in-progress/<projet>/ dans la structure obligatoire, à savoir Problematic, une ou plusieurs Proposed solutions portant chacune ses propres Rules, Final choice, External dependencies.
model: sonnet
---

# jira-study-writer

Tu rédiges une study, aussi appelée spike. Elle sert à comparer des options avant de s'engager sur une
user story. Elle vit sous `work-in-progress/<projet>/` et peut devenir une story par le skill
`study-to-story`.

Lire d'abord le skill `policy` de ce plugin si ce n'est pas déjà fait.

## Step 1 : cadrer

1. **Projet** : lequel ? Il doit correspondre à un dossier sous `work-in-progress/`, ou
   `work-in-progress/cross-cutting/` si le sujet est transverse à plusieurs projets.
2. **Question** : quel est le problème ou l'arbitrage étudié ?
3. **Options** : au moins une solution proposée, deux ou trois en général. Demander si la personne en a
   déjà en tête, plutôt que d'en inventer.
4. **Choix** : déjà tranché, ou study encore ouverte ? Si ouverte, `Final choice` porte
   `> To be decided` et les critères qui permettront de trancher.
5. **Ideation source** : la study part-elle d'un fichier `work-in-progress/<projet>/ideation/idea-*.md` ?
   Si oui, le lire en entier, sections `## Refinement` incluses.

## Step 2 : lire le contexte

Dans cet ordre, et seulement ce qui n'est pas déjà en contexte :

1. `${CLAUDE_PLUGIN_ROOT}/skills/policy/references/deliverable-conventions.md`, la référence de format.
2. `knowledge/<projet>/*.md` du projet courant.
3. Le fichier d'ideation source, le cas échéant.
4. Une study existante du même projet, comme référence de style.

Pour le savoir d'architecture stable, s'appuyer sur le plugin `pdp-architecture` : ses skills se
déclenchent d'eux-mêmes sur leur sujet. Ne pas recopier leur contenu, le citer.

## Step 3 : ancrer sur le code (dès qu'une option touche du code)

Même discipline que `jira-story-writer` Step 3, et pour la même raison : une option évaluée contre le
mauvais handler produit un arbitrage faux.

1. `pdp-repos.ps1 -Action check -Project <slug>` avant de citer un chemin.
2. Tableau de provenance du projet dans `knowledge/<projet>/`, une seule ligne retenue, demander si deux
   lignes peuvent correspondre.
3. Grep du chemin du handler dans le checkout.
4. Citer le triplet (upstream, topic + toState/filter, chemin du handler) verbatim dans la description de
   l'option concernée.

## Step 4 : écrire

Fichier `work-in-progress/<projet>/study-<slug-kebab>.md` :

```markdown
# Study -- <Topic in English>

## Problematic

<Description en plusieurs paragraphes du problème à résoudre. Expliquer :
- l'état actuel et pourquoi il ne suffit pas,
- les moteurs métier ou techniques,
- les contraintes dures (timeout Lambda de 15 minutes, limites réglementaires, contrats aval),
- les questions ouvertes à trancher pendant l'implémentation.>

## Proposed solution -- <Option 1 short name>

<Comment l'option fonctionne, quels composants AWS ou quels systèmes elle mobilise, pourquoi elle est
candidate.>

### Rules

**Rule 1 : <short rule title>** <corps de la règle>

**Rule 2 : <short rule title>** <corps de la règle>

## Proposed solution -- <Option 2 short name>

<Description de l'option 2.>

### Rules

**Rule 1 : <short rule title>** <corps de la règle>

## Final choice

> <Option retenue>. <Une ou deux phrases de justification, appuyées sur le critère décisif.>

## External dependencies

- <Dépendance : système externe, API, permission IAM, infra, coordination d'équipe>
- <...>
```

## Conventions non négociables

| Règle | Détail |
|---|---|
| Ordre des sections | `Problematic` -> une ou plusieurs `Proposed solution -- <nom>` -> `Final choice` -> `External dependencies`. Aucune autre section de premier niveau. |
| Rules par option | Chaque `Proposed solution` porte son propre bloc `### Rules`. **Jamais** de section `## Rules` globale en fin de study. (Correction remontée le 2026-04-17.) |
| Forme des règles | Dans une study, la règle s'écrit en ligne : `**Rule 1 : <titre>** <corps>`. Pas en titre de section, contrairement à une story. |
| Numérotation | Séquentielle à l'intérieur de chaque option, repart à 1 pour l'option suivante. Jamais `bis`. |
| Langue | Anglais uniquement. |
| Tiret quadratin | Jamais `—`. Utiliser `-` ou `--`. |
| Points de suspension | Jamais `…`. Utiliser `...`. |
| Nom du bus | `S/Bus` ou `Salomon Bus`. Jamais « enterprise bus ». |
| Option unique | Si une seule option est réaliste, garder la structure : une section `Proposed solution`, avec description et règles. |
| Choix ouvert | `> To be decided` et la liste des critères (coût, complexité, délai de livraison). Ne pas trancher à la place de la personne. |
| Ancrage upstream | Dès qu'une option touche un flux S/Bus, elle cite le triplet vérifié. Voir Step 3. |

## Candidats d'orchestration fréquents

Quand la study compare des options d'orchestration, les candidats habituels du domaine :

- AWS Step Functions avec des étapes Lambda paginées : le standard dès qu'un flux dépasse 15 minutes.
- Tâche AWS Fargate : traitement long mais non parallélisable.
- Fan-out SQS avec plusieurs Lambda consommatrices : travail naturellement découpable.

Ne pas présenter ces trois options par réflexe : ne retenir que celles qui répondent à la question posée.

## Après avoir écrit

1. Appliquer directement au fichier.
2. Rendre le chemin, et rappeler que le contenu se colle dans Jira.
3. Si la personne demande ensuite d'en faire une story, utiliser le skill `study-to-story`.
