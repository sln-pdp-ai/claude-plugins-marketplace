# pdp-po-workbench

L'atelier de rédaction du PO sur le domaine PDP Salomon / Amer Sports : user stories et studies Jira,
pages Confluence, ideation, lint des livrables, et la synchro qui régénère en local le savoir périssable à
partir du code des services.

Les livrables sont des fichiers Markdown, relus et versionnés, que vous collez vous-même dans Jira ou
Confluence. Ce plugin n'écrit jamais dans un ticket ni dans une page : c'est bloqué techniquement.

## Installation

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install pdp-po-workbench@pdp-ai
```

Si l'installation annonce `Run /reload-plugins to activate`, lancer `/reload-plugins`.

Installer aussi `pdp-architecture` : il porte le savoir d'architecture stable, que ce plugin cite au lieu
de le dupliquer. Le workbench fonctionne sans lui, moins bien.

```
/plugin install pdp-architecture@pdp-ai
```

Prérequis : Windows avec PowerShell 5.1 (les scripts en dépendent), git, et l'accès GitLab aux dépôts des
services, VPN compris.

## Où l'installer

Dans **votre** dépôt de savoir, celui où vivent vos livrables. Pas dans un dépôt de code de service : le
plugin y lit le code, il n'y écrit rien.

Structure attendue, une entrée par projet :

```
knowledge/core/           conventions locales, sync-state.md
knowledge/<projet>/       savoir derive du code (regenere, pas ecrit a la main)
user-stories/<projet>/    user-story-<slug>.md
work-in-progress/<projet>/  study-<slug>.md, ideation/idea-<slug>.md
confluence-documentation/<projet>/
local-repos/              clones de travail des services, ignores par git
```

Dépôt vide : le skill `project-onboarder` l'amorce, y compris la ligne `local-repos/` du `.gitignore`.

## Ce que le plugin apporte

| Skill | Rôle |
|---|---|
| `policy` | la doctrine : arborescence, résolution des checkouts, ancrage upstream, périmètre d'écriture. Point d'entrée |
| `jira-story-writer` | une user story prête à coller : Introduction, Rules numérotées, Acceptance Criteria Cucumber |
| `jira-study-writer` | une study : Problematic, options portant chacune ses Rules, Final choice, dépendances |
| `study-to-story` | promotion d'une study tranchée en user story, avec liens croisés |
| `deliverable-linter` | contrôle de format d'une story ou d'une study, et correction sur demande |
| `confluence-page-writer` | une page Confluence, diagramme Mermaid en option |
| `idea-incubator` | un fichier d'ideation libre, hors conventions |
| `idea-refiner` | une passe de digestion sur une ideation : synthèse, questions ouvertes, pistes. En ajout seul |
| `project-onboarder` | les dossiers d'un nouveau projet, et l'amorçage d'un dépôt neuf |
| `knowledge-sync` | régénère `knowledge/<projet>/` depuis le code, via le sous-agent `codebase-syncer` |

Les skills se déclenchent d'eux-mêmes quand la conversation touche leur sujet. Pour forcer l'un d'eux :
`/pdp-po-workbench:jira-story-writer`.

## L'ancrage upstream, la règle qui compte

Un mot métier ne prouve jamais quel code est visé. « master data », « article », « catalog », « publish »
désignent plusieurs topics et plusieurs handlers dans le même service : SAP et PLM émettent tous les deux
de la « master data » vers `sln-merchagg`, sur des topics différents.

Dès qu'une règle touche un flux S/Bus, elle cite le quadruplet **(système amont, topic + toState/filter,
chemin complet du handler, cible d'écriture)**, pris dans le tableau de provenance du projet et vérifié
par un grep dans le checkout. Une story bien rédigée mais mal ancrée passe la revue, et le dev implémente
au mauvais endroit.

## Les checkouts de code

Le plugin ne suppose aucun chemin. Il les résout dans cet ordre :

1. `PDP_REPOS_DIR`, si la variable pointe un dossier qui contient déjà les checkouts ;
2. le projet courant, s'il **est** le dépôt cherché ;
3. un dépôt frère `../<nom>` ;
4. un clone de travail dans `local-repos/`, provisionné par le plugin.

Les trois premiers sont vos dépôts : le plugin ne les rafraîchit jamais lui-même. Le quatrième est une
copie de lecture, que seul `-Action update` touche, en fast-forward.

Le manifeste des projets, des dépôts, des branches et des zones à scanner vit dans
[bin/pdp-lib.ps1](bin/pdp-lib.ps1). Ajouter un projet ou un service se fait là, dans le dépôt du plugin,
et demande un bump de version.

Vérifications utiles en direct :

```
powershell -NoProfile -ExecutionPolicy Bypass -File bin/pdp-repos.ps1 -Action list
powershell -NoProfile -ExecutionPolicy Bypass -File bin/pdp-repos.ps1 -Action paths
powershell -NoProfile -ExecutionPolicy Bypass -File bin/pdp-repos.ps1 -Action check -Project merch-aggregator
```

## Le savoir : ce qui est régénéré, ce qui est écrit à la main

| | Où | Cadence | Qui écrit |
|---|---|---|---|
| Savoir **stable** : sémantique du S/Bus, exposition d'API, feature flags, journalisation, persistance, carte des systèmes | plugin `pdp-architecture` | trimestre | à la main, relu, publié |
| Savoir **périssable** : handlers, topics, souscriptions, schémas, provenance | `knowledge/<projet>/` chez vous | sprint | `knowledge-sync`, jamais à la main |

Conséquence : ne pas ajouter un fait à la main dans `knowledge/<projet>/`, il sera écrasé au prochain run.
Un savoir qui mérite de durer relève de `pdp-architecture`, donc du dépôt du plugin.

L'état de synchronisation vit dans `knowledge/core/sync-state.md`, chez vous, à côté du savoir qu'il
décrit. Il ne peut pas vivre dans le plugin : un plugin installé est une copie en cache, écrasée à chaque
mise à jour.

## Ce que le plugin bloque, et pourquoi

Un plugin ne peut pas livrer de règle `permissions.deny`. Trois hooks `PreToolUse` les reconstituent :

| Bloqué | Raison | Échappatoire |
|---|---|---|
| écritures Jira et Confluence | un livrable passe par un fichier relu et versionné, jamais directement dans un ticket | `PDP_ALLOW_ATLASSIAN_WRITES=1` |
| écritures de fichier dans un checkout de code | ce sont les dépôts des équipes de dev, lus en source | aucune |
| commandes git mutantes visant un checkout | sans ça, l'interdiction d'écrire ne servirait à rien : un `git reset` fait les mêmes dégâts | aucune |

Ce qui n'est **pas** bloqué, volontairement : les écritures dans votre projet courant. Vous y écrivez vos
livrables et votre savoir.

Limite connue : les outils MCP d'écriture Atlassian sont énumérés nommément (les jokers sur les noms
d'outils MCP ne sont pas fiables). Un nouvel outil d'écriture apparu côté MCP ne serait pas bloqué tant
qu'il n'a pas été ajouté au matcher de [hooks/hooks.json](hooks/hooks.json).

## Un hook injecte la doctrine au démarrage

Un plugin ne peut pas livrer de `CLAUDE.md` chargé comme contexte de projet. Le hook `SessionStart`
injecte le noyau de la doctrine et l'état du périmètre, sans accès réseau : un fetch au démarrage
bloquerait la session hors VPN. Le détail est dans le skill `policy`.
