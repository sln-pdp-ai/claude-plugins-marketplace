# Conventions des livrables PDP

Référence canonique des formats Jira et Confluence du domaine PDP Salomon / Amer Sports. Les skills de
rédaction de ce plugin reprennent chacun le sous-ensemble qui les concerne ; en cas d'écart entre un
`SKILL.md` et ce fichier, **ce fichier fait autorité**.

Les livrables sont rédigés en **anglais**. Ce fichier est en français : il décrit les règles, il n'est pas
un livrable.

## Cadence

Sprints de deux semaines. PI planning tous les trois mois (emprunté à SAFe). Une story est dimensionnée
pour tenir dans un sprint ; ce qui n'y tient pas se découpe ou passe par une study.

## User story

Trois blocs obligatoires, dans cet ordre : `Introduction`, `Rules`, `Acceptance Criteria`. Puis
`External dependencies` si le sujet en a.

### Introduction

Chaque mot-clé sur sa propre ligne. Jamais de paragraphe condensé, jamais de section `## Context` à la
suite : le contexte dont le dev a besoin va dans la `Rule` correspondante.

```markdown
## Introduction

**AS** <role>,
**I WANT TO** <capability>,
**AND** <additional capability if any>,
**SO THAT** <business value>,
**AND** <additional value if any>.
```

### Rules

Le cœur de la description. Le séparateur entre le numéro et le titre est `:` (deux-points), jamais `--`
ni `-`. Une règle peut porter des schémas, des extraits TypeScript ou JSON, des noms de topics.

```markdown
### Rule 1 : <short rule title>

<rule body>
```

Numérotation strictement séquentielle : `Rule 1`, `Rule 2`, `Rule 3`. Jamais `Rule 4 bis`, jamais de
suffixe alphabétique. Insérer une règle au milieu impose de renuméroter toutes les suivantes.

### Acceptance Criteria

Style Cucumber, **hors bloc de code**. La clôture ` ```gherkin ` est interdite : Jira n'en fait rien de
lisible. Les mots-clés Gherkin sont en gras, en début de ligne, suivis de leur clause sur la même ligne.
Chaque AC porte un titre.

```markdown
### _AC1 <short AC title>_

**Given** <context>
**When** <event>
**Then** <expected outcome>
**And** <additional outcome>
```

Viser au moins quatre AC : chemin nominal, cas d'erreur, cas limite, et rejeu ou non-régression dès que
la story touche un flux existant ou un topic `-request`.

### Titre

Anglais. Un emoji en préfixe est possible, seulement si la personne le demande :

| Emoji | Sens |
|---|---|
| ⌛ | en attente |
| 💥 | urgent ou critique |
| ➕ | nice to have, à prendre s'il reste de la capacité en fin de sprint |

## Study (spike)

Quatre sections, dans cet ordre, et aucune autre au premier niveau :

```markdown
# Study -- <Topic in English>

## Problematic

## Proposed solution -- <Option name>

### Rules

## Final choice

## External dependencies
```

Points qui se trompent le plus souvent :

- **Les Rules sont par option.** Chaque `Proposed solution` porte son propre bloc `### Rules`. Jamais de
  section `## Rules` globale en fin de document. (Correction remontée le 2026-04-17.)
- Dans une study, la règle s'écrit en ligne : `**Rule 1 : <titre>** <corps>`, pas en titre de section.
- La numérotation repart à 1 dans chaque option.
- Une seule option réaliste : garder la structure, une seule section `Proposed solution`.
- Choix non tranché : `> To be decided`, suivi des critères qui permettront de trancher (coût,
  complexité, délai).

## Page Confluence

En-tête `Audience` / `Status` / `Last update`, puis les sections utiles au type de page : vue
d'architecture, runbook d'intégration, contrat d'API, onboarding, décision. Diagrammes en blocs
` ```mermaid ` (Confluence les rend nativement quand la macro est activée), sous quinze nœuds. Éviter
`${...}`, `{`, `}`, `<` et `>` dans les libellés de nœuds : Mermaid casse dessus. Utiliser `&lt;` et
`&gt;` pour les génériques.

## Vocabulaire

| À écrire | Jamais |
|---|---|
| `S/Bus`, `Salomon Bus` | « enterprise bus » |
| `-` ou `--` | `—` (tiret quadratin, U+2014) |
| `...` | `…` (U+2026) |
| AWS Lambda, AWS Step Functions, Serverless Framework v3, JSON Schema, MongoDB, DynamoDB | des approximations maison |
| rejeu via topic `-request`, `correlationId` | « replay endpoint », « trace id » |

## Ancrage upstream

Une story ou une study qui touche un flux S/Bus entrant ou sortant ancre chaque règle concernée sur le
quadruplet **(système amont, topic + toState/filter, chemin complet du handler, cible d'écriture)**, pris
dans le tableau de provenance du projet et vérifié par grep dans le checkout.

Le vocabulaire métier n'est pas une preuve. Une story qui dit « PLM » mais pointe un topic alimenté par
SAP est à rejeter en revue, même si tout le reste est impeccable.

## Ce qui échappe à ces conventions

Les fichiers d'ideation sous `work-in-progress/<projet>/ideation/`. Le texte brut y est libre : mélange
français / anglais, tirets quadratins, contradictions, notes en vrac. Les conventions reprennent quand
l'idée devient une study. Le seul texte contraint dans un fichier d'ideation est celui que les skills y
ajoutent, dans les sections `## Refinement`.
