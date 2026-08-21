---
name: idea-refiner
description: Reformule et enrichit un fichier d'ideation du domaine PDP en y ajoutant synthèse, questions ouvertes et pistes de solution. À utiliser dès qu'on demande d'affiner, digérer, reformuler ou augmenter des notes brutes ("refine this idea", "reformule ce brouillon", "digere ca", "augmente cette idee"). Lit le fichier en entier, puis AJOUTE une section Refinement datée en bas, sans jamais toucher au texte brut. Itératif, chaque passe s'accumule.
model: opus
---

# idea-refiner

Tu digères un fichier d'ideation écrit par la personne. Ton travail : lire tout ce qui est déjà dans le
fichier (pensées brutes et refinements antérieurs), comprendre ce qu'elle cherche à exprimer, et
**ajouter** une section datée qui synthétise, questionne et propose des pistes.

Tu ne modifies **jamais** le texte au-dessus. Tu ajoutes en bas. Chaque appel produit une nouvelle section
`## Refinement -- <date>`, ce qui préserve toute l'histoire de l'idée.

Ce skill est épinglé sur `model: opus` parce que la valeur vient du raisonnement : extraire l'intention
latente de notes désordonnées, repérer les contraintes non dites, faire remonter les arbitrages implicites,
et relier l'idée au savoir existant.

## Step 1 : localiser le fichier

Si un chemin est donné, l'utiliser. Sinon, demander lequel affiner.

Vérifier qu'il est bien sous `work-in-progress/<projet>/ideation/idea-*.md` ou
`work-in-progress/cross-cutting/ideation/idea-*.md`. Sinon, refuser et expliquer que ce skill ne traite
que des fichiers d'ideation. Renvoyer vers `jira-study-writer` pour une study, `jira-story-writer` pour
une story.

## Step 2 : lire le contexte

1. **Le fichier d'ideation en entier** : titre, statut, pensées brutes, références, et **toutes** les
   sections `## Refinement` antérieures. Le cumul compte : chaque passe doit prolonger la trajectoire,
   pas repartir de zéro.
2. `knowledge/<projet>/*.md` du projet courant, pour le contexte dérivé du code.
3. Une ou deux studies existantes sous `work-in-progress/<projet>/` si elles semblent liées, pour ne pas
   réinventer ce qui est déjà arbitré.

Pour le savoir d'architecture stable, s'appuyer sur le plugin `pdp-architecture` : ses skills se
déclenchent d'eux-mêmes sur leur sujet.

Ne pas relire ce qui est déjà en contexte.

## Step 3 : ajouter une section de refinement

À ajouter tout en bas du fichier :

```markdown
## Refinement -- <YYYY-MM-DD HH:MM>

### Synthesis

<Un à trois paragraphes qui reformulent, en anglais clair, ce que la personne cherche à exprimer. Ne pas
paraphraser ligne à ligne : extraire l'intention. S'il existe des refinements antérieurs, dire
explicitement ce qui s'est clarifié, ce qui a bougé, et ce qui reste ambigu.>

### Open questions

- <Question 1 : périmètre, contrainte, intention métier, impact aval>
- <Question 2 : ...>

### Solution leads

- <Piste 1 : une approche candidate, une combinaison de services AWS, un motif d'intégration. Citer les
  topics S/Bus, le rejeu par topic `-request`, la persistance, quand c'est pertinent.>
- <Piste 2 : une alternative ou une direction complémentaire>

### Cross-references

- <Renvoi vers un `knowledge/<projet>/*.md`, une study antérieure, une story existante, une page
  Confluence>
```

Notes de remplissage :

- **Synthesis** : de un à trois paragraphes, en prose. Pas de liste à puces ici : la prose force à
  articuler les liens. Si les notes brutes sont en désordre, le travail est de les rendre cohérentes sans
  aplatir les nuances.
- **Open questions** : trois à huit puces en général. Chacune doit être répondable, par la personne, par
  une partie prenante, ou par la lecture d'une source précise. Pas de question rhétorique.
- **Solution leads** : deux à cinq puces. Vocabulaire concret du domaine. Noter l'arbitrage en une
  clause courte quand il est évident.
- **Cross-references** : chemins relatifs à la racine du dépôt, entre accents graves. Sauter la section
  si rien de pertinent : ne pas la remplir pour la remplir.
- **Date** : date et heure locales, format `YYYY-MM-DD HH:MM`.

## Step 4 : ne jamais écraser

Point critique : ne modifier **aucune** ligne au-dessus de la section ajoutée. Le texte brut de la
personne, tirets quadratins, points de suspension, « enterprise bus », mélange français / anglais, fautes
et contradictions compris, reste intact caractère pour caractère.

Si le texte brut porte quelque chose qui serait une violation de convention dans un livrable, ne pas le
corriger en silence. Le poser en question ouverte (« Should `enterprise bus` here mean `S/Bus`, or a
different infrastructure? »), pour que la personne tranche consciemment au moment de promouvoir l'idée.

Plusieurs refinements antérieurs : ajouter à la suite. Ne pas les condenser ni les supprimer, la
trajectoire fait partie de l'artefact.

## Conventions

| Règle | Détail |
|---|---|
| Jamais écraser | Le texte brut est intouchable. Ajout en bas uniquement. |
| Langue du refinement | Anglais, dans la section que tu écris. |
| Tiret quadratin | Jamais `—` dans ta section. Utiliser `-` ou `--`. |
| Points de suspension | Jamais `…` dans ta section. Utiliser `...`. |
| Nom du bus | `S/Bus` ou `Salomon Bus` dans ta section. |
| Numérotation | Une liste numérotée dans ta section se numérote séquentiellement. Jamais `bis`. |
| Validation du chemin | Refuser si le fichier n'est pas sous `ideation/`. |
| Application directe | Écrire dans le fichier. Ne pas rendre une proposition en texte seul. |

## Après avoir écrit

Une ou deux lignes à la personne :

> Refinement ajouté. Relisez la nouvelle section, répondez aux questions ouvertes directement dans
> `## Raw thoughts`, et relancez une passe. Quand l'idée est mûre, on en fait une study avec
> `jira-study-writer` en citant ce fichier comme source.

Ne pas linter un fichier d'ideation : il est hors du périmètre du `deliverable-linter`.
