---
name: study-to-story
description: Convertit une study finalisée du domaine PDP en user story Jira. À utiliser dès qu'on demande de transformer, convertir ou promouvoir une study ou un spike en story ("transform this study into a story", "transforme cette study en story", "promeus ce spike"). Lit la study sous work-in-progress/<projet>/, retient l'option marquée Final choice, en extrait les règles, et produit la story sous user-stories/<projet>/ avec un lien retour vers la study source.
model: haiku
---

# study-to-story

Tu convertis une study finalisée en user story. La comparaison d'options est déjà faite et une option est
retenue dans `## Final choice`. Ton travail est de porter les règles de cette option au format story.

## Step 1 : localiser la study

Si un chemin est donné, l'utiliser. Sinon, demander laquelle convertir.

La study vit sous `work-in-progress/<projet>/study-<sujet>.md`, ou
`work-in-progress/cross-cutting/study-<sujet>.md`.

## Step 2 : lire et découper

Lire la study en entier. En extraire :

1. **Topic** -> titre de la story.
2. **Problematic** -> matière de l'`Introduction` (AS / I WANT TO / SO THAT).
3. **Final choice** -> le nom de l'option retenue.
4. **Proposed solution -- <option retenue>** -> sa description devient du contexte à placer dans les
   règles, son bloc `### Rules` devient la section `Rules` de la story.
5. **External dependencies** -> repris verbatim.

Si `Final choice` porte `> To be decided` : STOP. Dire que la study doit être tranchée d'abord, et ne pas
choisir à la place de la personne.

Ignorer les options non retenues. Elles restent dans la study, qui garde la trace de l'arbitrage.

## Step 3 : produire la story

Produire le fichier `user-stories/<projet>/user-story-<slug-kebab>.md` avec la structure et toutes les
conventions du skill `jira-story-writer`.

Spécifique à la conversion :

- Première ligne sous le titre, le lien retour :
  `> Based on study: \`work-in-progress/<projet>/<fichier-study>.md\`.`
- Renuméroter les règles séquentiellement à partir de 1, sans supposer que celles de la study le sont.
- Passer la forme en ligne de la study (`**Rule 1 : <titre>** <corps>`) à la forme en titre de la story
  (`### Rule 1 : <titre>` puis le corps).
- Évaluer chaque règle : une règle longue de study se découpe souvent en plusieurs règles fines de story.
- Produire au moins quatre Acceptance Criteria depuis les règles : le chemin nominal, chaque cas d'erreur
  majeur, et un cas de rejeu ou de non-régression dès qu'une règle mentionne un topic `-request` ou un
  flux existant. La study n'en porte pas, c'est du travail neuf.
- Reprendre l'ancrage upstream de la study telle quelle si elle en porte un. Si elle n'en porte pas et
  que la story touche un flux S/Bus, appliquer le Step 3 de `jira-story-writer` : l'ancrage est
  obligatoire dans la story, même quand la study s'en est passée.

## Step 4 : lier dans les deux sens

Ajouter en bas de la study source, si ce n'est pas déjà présent :

```
> Promoted to user story: `user-stories/<projet>/user-story-<slug>.md`.
```

Ne rien modifier d'autre dans la study : elle est la trace de l'arbitrage.

## Step 5 : lint

Passer les contrôles du skill `deliverable-linter` sur la story produite. Corriger toute violation avant
de considérer le travail fait.
