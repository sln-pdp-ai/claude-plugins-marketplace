---
name: policy
description: Doctrine du workbench PO du domaine PDP et localisation des sources. À lire avant de rédiger une story, une study, une page Confluence ou une ideation, avant d'ancrer une règle sur du code, et avant d'invoquer un autre skill du workbench. Contient l'arborescence du projet, l'ordre de résolution des checkouts, la procédure d'ancrage upstream et le périmètre d'écriture.
---

# Doctrine pdp-po-workbench

Ce skill **est** la référence de la doctrine du workbench : elle ne vit nulle part ailleurs. Un plugin ne
peut pas livrer de `CLAUDE.md` : un fichier de ce nom à la racine d'un plugin n'est pas chargé comme
contexte de projet. Le noyau est donc injecté au démarrage par un hook, et le détail est ici.

## Priorité absolue : l'ancrage prime sur la fluidité

Une story bien rédigée mais mal ancrée est pire qu'une story brouillonne : elle passe la revue et le dev
implémente sur le mauvais handler.

- Un mot métier ne prouve **jamais** quel code est visé. « master data », « article », « catalog »,
  « drop », « publish », « PLM » : plusieurs upstreams distincts partagent le même vocabulaire. SAP et
  PLM émettent tous les deux de la « master data » vers `sln-merchagg`, sur des topics différents.
- Dès qu'une règle touche un flux S/Bus entrant ou sortant, elle cite le quadruplet **(système amont,
  topic + toState/filter, chemin complet du handler, cible d'écriture)**. Voir « Ancrage upstream ».
- Le chemin du handler se vérifie dans le checkout avant d'être écrit. Un chemin repris d'un
  `knowledge/` non rafraîchi est une affirmation périmée déguisée en source.
- Deux lignes du tableau de provenance peuvent correspondre à la demande : dans ce cas, STOP et demander
  laquelle. Ne jamais trancher soi-même entre deux upstreams.
- Un projet sans tableau de provenance : proposer de le construire avant d'écrire la story, pas après.

## Arborescence du projet de l'utilisateur

Le workbench s'installe dans le dépôt de savoir du PO, pas dans un dépôt de code. Il y attend cette
structure, une ligne par projet du manifeste :

| Chemin | Contenu | Qui écrit |
|---|---|---|
| `knowledge/core/` | conventions locales, état de synchro | l'utilisateur, et la synchro pour l'état |
| `knowledge/<projet>/` | savoir **dérivé du code** : handlers, topics, schémas, provenance | la synchro, jamais à la main |
| `user-stories/<projet>/` | `user-story-<slug>.md`, prêtes à coller dans Jira | les skills de rédaction |
| `work-in-progress/<projet>/` | `study-<slug>.md`, plus `ideation/idea-<slug>.md` | les skills de rédaction |
| `confluence-documentation/<projet>/` | pages prêtes à coller dans Confluence | le skill Confluence |
| `local-repos/` | clones de travail des services, ignorés par git | le script du plugin seul |

`work-in-progress/cross-cutting/` accueille les studies et ideations transverses, qui ne relèvent d'aucun
projet du manifeste.

Conséquence à retenir : **`knowledge/<projet>/` est dérivé, pas rédigé**. Y ajouter un fait à la main le
fait disparaître à la prochaine synchro. Un savoir stable et écrit à la main n'a pas sa place ici : il
relève du plugin `pdp-architecture`.

## Où est le code, et est-il exploitable

Ne jamais supposer un chemin de checkout. Le plugin les résout, dans cet ordre :

1. la variable d'environnement `PDP_REPOS_DIR`, si elle pointe un dossier qui contient déjà les
   checkouts ;
2. le projet courant, s'il **est** le dépôt cherché (cas d'un dev dans son service) ;
3. un dépôt frère `../<nom>` (cas d'un poste où les services sont côte à côte) ;
4. un clone de travail dans `local-repos/` du projet courant.

Les trois premiers sont des dépôts que l'utilisateur gère lui-même. Le quatrième est une copie gérée par
le plugin, la seule qu'il ait le droit de rafraîchir.

Avant tout ancrage sur du code, et avant toute synchro :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/pdp-repos.ps1" -Action check -Project <slug>
```

Toujours restreindre avec `-Project` au projet traité : les huit projets font douze checkouts, et
fetcher les douze pour une story qui n'en touche qu'un coûte cher pour rien. `-Action paths` répond sans
accès réseau quand seule la localisation est en jeu, `-Action list` répond sans accès disque quand seul
le périmètre est en jeu.

Interprétation des verdicts :

- `A_JOUR` : continuer.
- `EN_RETARD` sur un clone de travail géré (`CLONE DE TRAVAIL` dans `-Action paths`) : proposer
  `-Action update` (fast-forward uniquement, rien n'écrit jamais sur ce clone), puis l'exécuter dès que
  l'utilisateur autorise l'appel. Il n'a rien à taper lui-même.
- `EN_RETARD` sur un dépôt géré par l'utilisateur : ne jamais le rafraîchir soi-même, c'est son dépôt et
  il peut y avoir du travail en cours. Donner le nombre de commits et la date, et lui laisser la main.
- `FETCH_KO` : la fraîcheur est invérifiable, donc l'ancrage l'est aussi. Le dire avant de citer un
  chemin de handler.
- `BRANCHE_KO` : la branche du manifeste n'existe pas sur ce dépôt. Le signaler ; le manifeste du plugin
  est à corriger, ce n'est pas à contourner par une autre branche choisie au hasard.
- `ARBRE_KO` : clone de travail incomplet, typiquement un `ensure` interrompu au checkout. Les objets
  sont là et `HEAD` est sur la bonne cible, mais des fichiers manquent sur le disque : ce verdict existe
  précisément parce que ce cas répondait `A_JOUR`. Ne rien ancrer et ne pas synchroniser dessus.
  Proposer de supprimer le dossier du clone, puis `-Action ensure -Project <slug>`.
- `ABSENT` : annoncer ce qui va être cloné et où, puis `-Action ensure -Project <slug>`. Si le script
  signale que `.gitignore` gagnerait à ignorer `local-repos`, proposer d'abord cette édition : sans elle
  les clones partent dans le cache utilisateur.

## Ancrage upstream, procédure

1. Ouvrir le tableau de provenance du projet dans `knowledge/<projet>/` : une section « Ingress data
   provenance », « Bus callback endpoints » ou équivalente, qui mappe `upstream -> topic -> handler ->
   écrit -> gate`.
2. Repérer la ligne qui correspond à l'intention. Deux lignes possibles : demander, ne pas deviner.
3. Vérifier que le handler existe dans le checkout, par un grep sur son chemin. Le `knowledge/` peut
   être en retard sur le code.
4. Citer verbatim dans la règle concernée : le système amont, le topic et son toState/filter, le chemin
   complet du handler depuis la racine du checkout, et le domaine d'écriture.

Pas de tableau de provenance sur ce projet : le construire d'abord, par la synchro
(`knowledge-sync`), ou à défaut le signaler comme un manque bloquant pour l'ancrage.

## Rapport avec les autres plugins

- `pdp-architecture` porte le savoir **stable** : sémantique du S/Bus, exposition d'API, feature flags,
  journalisation, persistance, carte des systèmes autoritaires. Ses skills se déclenchent d'eux-mêmes
  quand la conversation touche leur sujet. Ne pas recopier leur contenu dans un livrable : le citer, et
  laisser le savoir à sa place. Le workbench fonctionne sans lui, moins bien.
- Ce plugin-ci porte le **périssable** : ce qui se régénère depuis le code, et les livrables.
- Les plugins `smt-*` couvrent une autre initiative. Aucun rapport, aucune resynchronisation entre eux.

## Périmètre d'écriture

- Aucune écriture Jira, aucune écriture Confluence. Un livrable est un fichier Markdown relu et
  versionné, que la personne colle elle-même. Bloqué techniquement par un hook `PreToolUse`.
- Aucune écriture, aucun commit, aucune commande git mutante dans un checkout de code : ce sont les
  dépôts des équipes de dev. Bloqué par le même hook. Une correction de code se rend en proposition dans
  la story.
- Seul `pdp-repos.ps1 -Action update` touche un clone de travail, en fast-forward.
- Exception assumée : le dépôt que l'utilisateur a ouvert comme projet courant n'est pas protégé. Le PO
  écrit ses livrables et son savoir chez lui.
- Le texte brut d'un fichier d'ideation ne se corrige jamais, même pour une violation de convention.
  Voir le skill `idea-refiner`.

## Conventions de rédaction

Les conventions complètes, qui font autorité pour tous les skills de ce plugin, sont dans
[references/deliverable-conventions.md](references/deliverable-conventions.md). Le noyau, non
négociable :

- livrables en **anglais**, même quand la demande et les notes sont en français ;
- jamais le tiret quadratin (`—`) ni les points de suspension en un caractère (`…`) : `-` et `...` ;
- `S/Bus` ou `Salomon Bus`, jamais « enterprise bus » ;
- numérotation des Rules strictement séquentielle, jamais de `bis` ni de suffixe ;
- pas de section `## Context` dans une story : le contexte va dans la Rule concernée.
