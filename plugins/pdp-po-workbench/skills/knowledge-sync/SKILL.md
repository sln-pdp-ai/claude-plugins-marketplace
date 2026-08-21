---
name: knowledge-sync
description: Régénère le savoir local dérivé du code des services PDP, sous knowledge/<projet>/. À utiliser quand on demande de synchroniser, rafraîchir ou reconstruire la compréhension d'un projet depuis son code ("sync knowledge", "rafraichis le savoir", "mets a jour l'archi depuis le code"), et avant une story ou une study qui a besoin d'un ancrage upstream fiable. Provisionne les checkouts manquants, contrôle leur fraîcheur, puis délègue au sous-agent codebase-syncer.
model: sonnet
---

# knowledge-sync

Tu pilotes la régénération de `knowledge/<projet>/` à partir du code réel. Le travail d'ingestion lui-même
appartient au sous-agent `codebase-syncer` ; ton rôle est de préparer le terrain, de le lancer sur le bon
périmètre, et de rendre un compte rendu honnête.

Lire d'abord le skill `policy` de ce plugin si ce n'est pas déjà fait.

## Pourquoi ce skill existe

Le savoir de `knowledge/<projet>/` est **dérivé et périssable** : chemins de handlers, noms de topics,
listes de souscriptions, propriétés de schémas. Il change à chaque sprint. C'est pour ça qu'il se
régénère chez la personne au lieu d'être publié dans un plugin : un fait périmé figé dans un plugin est
faux en silence, et les stories écrites dessus sont fausses aussi.

Le savoir **stable** ne passe pas par ici : il vit dans le plugin `pdp-architecture`, écrit à la main.

## Step 1 : cadrer le périmètre

1. Quel projet ? Toujours demander, ou déduire du sujet en cours. Le manifeste :
   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action list
   ```
2. Ne lancer `-Project all` que si la personne le demande explicitement : huit projets font douze
   checkouts, donc douze fetch et une ingestion longue. Le défaut raisonnable est le projet de la story
   en cours.

## Step 2 : rendre les checkouts exploitables

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action check -Project <slug>
```

Selon les verdicts, en suivant le skill `policy` :

- `ABSENT` : annoncer ce qui va être cloné et où, proposer d'abord l'ajout de `local-repos/` au
  `.gitignore` si le script le signale, puis `-Action ensure -Project <slug>`.
- `EN_RETARD` sur un clone de travail géré : proposer `-Action update -Project <slug>`, puis l'exécuter.
- `EN_RETARD` sur un dépôt que la personne gère : ne pas y toucher. La synchro lit de toute façon la
  référence distante, donc elle reste correcte ; le signaler sans bloquer.
- `FETCH_KO` ou `BRANCHE_KO` : exclure ce checkout du run et le dire. Produire du savoir sur un dépôt dont
  on ne peut pas lire la référence distante serait de l'invention.

## Step 3 : lancer le sous-agent

Récupérer les entrées :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action zones -Project <slug>
```

Puis déléguer au sous-agent `codebase-syncer`, en lui passant pour chaque checkout : le slug du projet, le
chemin, la référence distante, son SHA, et la liste des zones. Il ne doit deviner aucun chemin.

Lui rappeler dans la consigne :

- l'état de synchronisation vit dans `knowledge/core/sync-state.md` du projet courant ;
- l'écriture se limite à `knowledge/` ;
- le tableau de provenance (`## Ingress data provenance`) est la priorité du run, parce que c'est lui qui
  rend l'ancrage des stories possible.

Sur un `-Project all`, lancer un sous-agent par projet plutôt qu'un seul pour les huit : le contexte d'un
projet ne sert pas à un autre, et un échec reste circonscrit.

## Step 4 : restituer

Reprendre le compte rendu du sous-agent, et y ajouter ce qu'il ne pouvait pas savoir :

- les checkouts exclus du run et pourquoi ;
- si un dépôt géré par la personne était en retard sur sa référence distante, sans que cela invalide le
  savoir produit ;
- ce qui reste à faire à la main, par exemple un tableau de provenance qu'aucun handler d'entrée n'a permis
  de construire.

Ne jamais présenter un run partiel comme complet. Un projet dont un seul checkout sur trois a été ingéré a
un savoir incomplet, et une story ancrée dessus peut viser le mauvais service.

## Ce que ce skill ne fait pas

- Il n'écrit aucun livrable. Une fois le savoir à jour, la story se rédige avec `jira-story-writer`.
- Il ne touche pas au code des checkouts, et n'exécute aucune commande git mutante : un hook du plugin les
  bloque de toute façon.
- Il ne remplace pas la lecture du code au cas par cas. Avant de citer un chemin de handler dans une
  story, le grep dans le checkout reste obligatoire, même juste après une synchro.
