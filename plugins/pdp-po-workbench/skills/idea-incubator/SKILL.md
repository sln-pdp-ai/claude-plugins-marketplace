---
name: idea-incubator
description: Crée un fichier d'ideation libre sous work-in-progress/<projet>/ideation/ pour le domaine PDP Salomon / Amer Sports. À utiliser dès qu'on demande de démarrer une idée, un brainstorm ou une ideation ("new idea", "brainstorm X", "ecris une idee", "incube cette idee", "fais-moi un fichier d'ideation"). Produit un gabarit vide que la personne remplit à la main avant d'appeler idea-refiner. Les conventions des livrables ne s'appliquent volontairement pas au texte brut écrit ici.
model: sonnet
---

# idea-incubator

Tu crées un **fichier d'ideation libre**. C'est l'entrée d'une boucle :

1. ce skill crée le gabarit vide ;
2. la personne y écrit ses pensées brutes sous `## Raw thoughts` ;
3. le skill `idea-refiner` ajoute une section `## Refinement` datée : synthèse, questions ouvertes,
   pistes de solution. Itératif, jamais destructif ;
4. quand l'idée est mûre, le skill `jira-study-writer` la reprend comme source.

Le fichier vit sous `work-in-progress/<projet>/ideation/idea-<slug-kebab>.md`. Ce **n'est pas** un
livrable : les conventions imposées aux stories, studies et pages Confluence ne s'appliquent pas au texte
brut que la personne va écrire.

## Step 1 : cadrer

1. **Projet** : lequel ? Il doit correspondre à un dossier sous `work-in-progress/`, ou
   `cross-cutting` pour une idée transverse.
2. **Sujet** : quelle idée, quelle question ? Demander si ce n'est pas donné.
3. Si le dossier du projet n'existe pas, proposer le skill `project-onboarder` d'abord.

## Step 2 : préparer le sous-dossier

S'assurer que `work-in-progress/<projet>/ideation/` existe, le créer sinon. Pas besoin de `.gitkeep` si
le fichier d'idée y est écrit immédiatement.

## Step 3 : écrire le gabarit

Fichier `work-in-progress/<projet>/ideation/idea-<slug-kebab>.md`, exactement ce gabarit :

```markdown
# Idea -- <Topic in English>

> Created: <YYYY-MM-DD>
> Status: incubating

## Raw thoughts

<!-- Ecrivez librement ici. Puces, idees a moitie formees, questions, esquisses, references, melange
francais / anglais : tout passe. Les conventions des livrables (pas de tiret quadratin, pas de points de
suspension en un caractere, S/Bus, numerotation sequentielle, anglais obligatoire) ne s'appliquent PAS a
cette section. Elles reprennent quand l'idee devient une study. -->

## References

<!-- Facultatif : liens vers des studies, des fichiers de savoir, des tickets Jira, des pages Confluence,
des chemins de code. -->
```

Notes de remplissage :

- **Titre** : anglais, court, descriptif, calqué sur le sujet donné.
- **Created** : la date du jour, format `YYYY-MM-DD`.
- **Status** : toujours `incubating` à la création. La personne le fera évoluer elle-même (`mature`,
  `promoted to study <fichier>`, `abandoned`).
- Laisser `## Raw thoughts` et `## References` vides sous leurs commentaires. Ne rien pré-remplir : tout
  l'intérêt est que ce soit la personne qui écrive.

## Conventions

| Règle | Détail |
|---|---|
| Langue du gabarit | Le gabarit lui-même (titre, statut, commentaires) est en anglais, sauf les commentaires d'aide qui peuvent être en français. |
| Chemin | Toujours `work-in-progress/<projet>/ideation/idea-<slug>.md`. Jamais à plat dans `work-in-progress/<projet>/`. |
| Slug | Kebab-case minuscule, dérivé du sujet. Sujet « store asset URLs in Salsify » -> `idea-store-asset-urls-in-salsify.md`. |
| Contenu brut exempté | Ne **jamais** appliquer les conventions des livrables au texte de la personne. Le gabarit l'invite même à mélanger français et anglais. |
| Application directe | Écrire le fichier. Ne pas rendre une proposition en texte seul. |

## Après avoir écrit

Rendre le chemin exact, et une phrase d'usage :

> Écrivez vos pensées brutes sous `## Raw thoughts`, sans vous soucier des conventions. Quand vous voulez
> que je digère, lancez le skill `idea-refiner` sur ce fichier. Autant de passes que vous voulez : chacune
> ajoute une section `## Refinement` datée sans toucher à votre texte.

Ne pas linter un fichier d'ideation : il est hors du périmètre du `deliverable-linter`.
