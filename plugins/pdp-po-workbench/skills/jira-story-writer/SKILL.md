---
name: jira-story-writer
description: Rédige une user story Jira prête à coller, pour un projet du domaine PDP Salomon / Amer Sports. À utiliser dès qu'on demande de créer, rédiger ou générer une user story ("write a story for X", "ecris une story", "fais-moi une US sur", "transforme ca en story"). Produit un fichier Markdown sous user-stories/<projet>/ au format obligatoire, avec une Introduction AS / I WANT TO / SO THAT, un bloc Rules numérotées séquentiellement et plusieurs Acceptance Criteria Cucumber. Ancre chaque règle qui touche un flux S/Bus sur le handler vérifié dans le code.
model: sonnet
---

# jira-story-writer

Tu rédiges une user story pour le domaine PDP. La sortie est un fichier Markdown que la personne colle
directement dans Jira : le format doit être exact, sans retouche à faire à la main.

Lire d'abord le skill `policy` de ce plugin si ce n'est pas déjà fait : arborescence, résolution des
checkouts, procédure d'ancrage, périmètre d'écriture.

## Step 1 : cadrer

Confirmer, si ce n'est pas déjà donné :

1. **Projet** : lequel ? Il doit correspondre à un dossier sous `user-stories/`. La liste des projets du
   manifeste s'obtient sans accès disque :
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action list
   ```
   Un projet inconnu du manifeste peut exister quand même comme dossier de livrables (sujet sans code
   adossé) : dans ce cas, dire qu'aucun ancrage sur du code ne sera possible. Dossier absent : proposer
   le skill `project-onboarder`.
2. **Source** : la story dérive-t-elle d'une study sous `work-in-progress/<projet>/` ? Si oui, la lire
   d'abord et reprendre les règles de l'option retenue. Si la conversion est le seul but, utiliser
   plutôt le skill `study-to-story`.
3. **Emoji de titre** : `⌛`, `💥`, `➕` ou aucun. N'en mettre aucun sans demande explicite.
4. **Ancrage upstream** : obligatoire dès que le titre, l'introduction ou une règle mentionne un système
   amont ou aval (PIM, PLM, SAP, GRM, Salsify, Aprimo, Atma, ECOM, B2B, master data, release, catalog).
   Voir Step 3.

## Step 2 : lire le contexte

Dans cet ordre, et seulement ce qui n'est pas déjà en contexte :

1. `${CLAUDE_PLUGIN_ROOT}/skills/policy/references/deliverable-conventions.md`, la référence de format.
2. `knowledge/<projet>/*.md` du projet courant : savoir dérivé du code, tableaux de provenance.
3. La study source sous `work-in-progress/<projet>/`, le cas échéant.
4. Une story existante du même projet, comme référence de style.

Pour le savoir d'architecture stable (sémantique du S/Bus, rejeu par topic `-request`, exposition d'API,
feature flags, journalisation, persistance), s'appuyer sur le plugin `pdp-architecture` : ses skills se
déclenchent d'eux-mêmes sur ces sujets. Ne pas réécrire son contenu dans la story, le citer.

## Step 3 : ancrer sur le code (obligatoire dès qu'un flux est en jeu)

Un mot métier ne prouve jamais quel handler est visé. « master data », « article », « catalog », « drop »,
« publish » désignent plusieurs topics et plusieurs handlers dans le même service.

1. Vérifier que le checkout est exploitable :
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action check -Project <slug>
   ```
   `FETCH_KO` ou `ABSENT` : le dire avant de citer un chemin, et suivre le skill `policy`.
2. Ouvrir le tableau de provenance du projet dans `knowledge/<projet>/` (section « Ingress data
   provenance », « Bus callback endpoints » ou équivalente).
3. Choisir la ligne qui correspond à l'intention. Deux lignes possibles : STOP, demander laquelle. Ne
   jamais trancher entre deux upstreams.
4. Grep le chemin du handler dans le checkout pour confirmer qu'il existe. Le `knowledge/` peut être en
   retard : un chemin non vérifié est une affirmation périmée déguisée en source.
5. Citer le quadruplet verbatim dans la `Rule 1` : système amont, topic + toState/filter, chemin complet
   du handler depuis la racine du checkout, domaine d'écriture.

Projet sans tableau de provenance : proposer de le construire par le skill `knowledge-sync` avant
d'écrire, ou signaler le manque comme bloquant pour l'ancrage.

## Step 4 : écrire

Fichier `user-stories/<projet>/user-story-<slug-kebab>.md` :

```markdown
# <Title in English> [emoji seulement si demandé]

> Based on study: `work-in-progress/<project>/<study-file>.md`. [seulement si dérivée d'une study]

## Introduction

**AS** <role>,
**I WANT TO** <capability>,
**AND** <additional capability if any>,
**SO THAT** <business value>,
**AND** <additional value if any>.

Project: **<repo-or-microservice-name>** [quand c'est pertinent]

---

## Rules

### Rule 1 : <short rule title>

<Corps de la règle. Peut porter des blocs de code, des exemples JSON, des extraits de schéma, des noms
de topics S/Bus.>

### Rule 2 : <short rule title>

<...>

---

## Acceptance Criteria

### _AC1 <short AC title>_

**Given** <context>
**When** <event>
**Then** <expected outcome>
**And** <additional outcome>

### _AC2 <short AC title>_

<...>

---

## External dependencies

- <dependency 1>
- <dependency 2>
```

## Conventions non négociables

| Règle | Détail |
|---|---|
| Langue | Anglais uniquement, même si les notes d'entrée sont en français. |
| Tiret quadratin | Jamais `—`. Utiliser `-`, ou `--` comme séparateur de titre. |
| Points de suspension | Jamais `…`. Utiliser `...`. |
| Nom du bus | `S/Bus` ou `Salomon Bus`. Jamais « enterprise bus ». |
| Numérotation | `Rule 1, Rule 2, Rule 3`, strictement séquentiel. Jamais `Rule 4 bis` ni de suffixe. Insérer une règle impose de renuméroter les suivantes. |
| Séparateur de titre de règle | `### Rule N : <titre>`, avec deux-points. Jamais `--` ni `-`. |
| Acceptance Criteria | Style Cucumber **hors bloc de code**. Pas de ` ```gherkin `. Titre `### _ACn <titre>_`. Mots-clés `**Given**`, `**When**`, `**Then**`, `**And**` en gras, en début de ligne, clause sur la même ligne. Au moins quatre AC : nominal, erreur, cas limite, rejeu ou non-régression. |
| Introduction | Chaque `**AS**`, `**I WANT TO**`, `**SO THAT**` et chaque `**AND**` sur sa propre ligne. |
| Pas de section Context | Aucune section `## Context` ni `## Contexte` après l'introduction. Le contexte utile au dev va dans la Rule concernée. La story reste un ticket, pas une note. |
| Ancrage upstream | Dès qu'un flux S/Bus est touché, la Rule 1 cite le quadruplet, pris dans le tableau de provenance et vérifié par grep. Voir Step 3. |
| Auto-validation | Avant de rendre, passer les contrôles du skill `deliverable-linter` sur le fichier écrit. |

## Après avoir écrit

1. Appliquer directement au fichier. Ne pas rendre une proposition en texte seul, sauf demande explicite
   de relecture.
2. Rendre le chemin du fichier, et rappeler que le contenu se colle dans Jira : ce plugin n'écrit jamais
   dans un ticket.
3. Signaler tout ancrage qui n'a pas pu être vérifié, plutôt que de laisser croire qu'il l'a été.
