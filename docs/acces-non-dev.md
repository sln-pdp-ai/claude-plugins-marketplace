# Accès des profils non-dev

**Document historique, conservé pour la trace de l'arbitrage.** La piste retenue (Claude Code hors
VSCode) a été mise en oeuvre le 2026-08-20, sous une forme que ce cadrage n'avait pas anticipée : un
**plugin** installé dans le projet de la personne, et non ce dépôt recopié sur son poste. Deux
conséquences pour la lecture de ce qui suit.

- Là où le document parle d'installer l'assistant, de `repos/` ou du script de bootstrap, la procédure
  actuelle est [demarrage-non-dev.md](demarrage-non-dev.md) : `/plugin marketplace add` puis
  `/plugin install`. Le dossier `repos/` et `scripts/bootstrap.ps1` n'existent plus.
- Le point « la source unique : hors de ce dépôt, les instructions sont une copie, et une copie dérive »
  reste vrai mais change de nature : le plugin est distribué depuis ce dépôt et versionné, donc la copie
  est traçable et se met à jour par `/plugin update`. La dérive redevient un problème de version, pas de
  recopie manuelle.

Note de cadrage d'origine, du 2026-07-29 au 2026-08-19 :

## Besoin

Des profils non-dev (sans VSCode) veulent chatter avec l'assistant SMT. Cas d'usage visés : comparer
specs et sources, proposer des refactorings, mettre à jour de la doc à partir des sources.

Deux contraintes tranchées le 2026-07-29 :

- **Le volet code est le cœur du besoin**, pas un complément. Une surface qui ne voit que Confluence
  et Jira ne répond pas au besoin exprimé.
- **Une install légère est acceptable** : ni IDE ni git en ligne de commande, mais une application
  desktop installée une fois et un script de bootstrap passent.

## Principe

Le projet tient en trois briques : les instructions, les connexions outils, l'accès au code. La
surface de chat est interchangeable ; les briques ne le sont pas toutes.

Portable d'une surface à l'autre :

- les instructions (`CLAUDE.md`) et les skills, recopiables ;
- le MCP Atlassian, via `.mcp.json` en Claude Code, via un Connecteur sur claude.ai et Slack. Depuis le
  2026-08-19 il ne couvre plus que Jira, et Confluence en lecture.

Non portable :

- l'accès à un système de fichiers, donc tout le volet code **et, depuis le 2026-08-19, tout le volet
  specs** : les spécifications et le glossaire sont des fichiers git (`repos/sln-smt-spec-owner`), plus
  des pages Confluence ;
- les garde-fous d'écriture **techniques** : les règles `deny` de `.claude/settings.json` (Jira et
  code) et la liste `tools:` du sous-agent `code-explorer` n'existent qu'en Claude Code. Ailleurs,
  ils redeviennent déclaratifs, c'est-à-dire une consigne que rien n'empêche de contourner ;
- la source unique : hors de ce dépôt, les instructions sont une copie, et une copie dérive.

## Grille de décision

| Critère | Piste 0 Claude Code | Piste 1 claude.ai Project | Piste 2 Slack | Piste 3 hébergé |
|---|---|---|---|---|
| Specs et glossaire (`repos/sln-smt-spec-owner`) | oui | non | non | oui |
| Jira, et Confluence en lecture | oui | oui | oui | oui |
| Code (`repos/`) | oui | non | non | oui |
| Skills et sous-agent | natifs | à recopier, partiel | à recopier, partiel | à réimplémenter |
| Garde-fous d'écriture | techniques (Jira, code) | déclaratifs | déclaratifs | à construire |
| Source unique des instructions | oui (`git pull`) | non (copie) | non (copie) | oui |
| Zéro install | non | oui | oui | oui |
| Délai | immédiat | jours | jours | semaines |
| Effort de construction | bootstrap + guide | recopie | recopie + app Slack | build, hébergement, sécu |
| Maintenance | clones à rafraîchir, par poste | resynchro instructions | resynchro instructions | exploitation du service |
| Coût | 1 siège Claude par personne | 1 siège par personne | 1 siège par personne | sièges ou API + hébergement |
| Passage à l'échelle | limité par l'install | bon | bon | bon |

## Pistes

### Piste 0 - Claude Code hors VSCode (retenue)

Claude Code existe en application desktop Windows / Mac et en CLI, indépendamment de VSCode. Le
non-dev installe l'application, lance un script de bootstrap qui clone ce dépôt puis les trois dépôts
SMT dans `repos/` (specs, backend, console), s'authentifie une fois sur GitLab (HTTPS) et une fois sur
Atlassian (OAuth via `/mcp`), et chatte.

Il hérite tel quel de `CLAUDE.md`, des 5 skills, de la commande `/explore-code`, du sous-agent
`code-explorer` et des règles `deny`. Rien à reconstruire, rien à resynchroniser : `git pull` suffit.

Limites : une install et un clone par poste ; un siège Claude, un compte GitLab et un compte
Atlassian par personne ; les clones doivent être rafraîchis pour rester fiables.

### Piste 1 - claude.ai Project + Connecteurs (quasi vidée de son intérêt)

Instructions du Project recopiées depuis `CLAUDE.md`, connecteur Atlassian déjà en place. Chat
navigateur, zéro installation. Couvre Jira, et Confluence en lecture.

Rétrogradée dès l'origine : ne couvre pas le code, donc ne répond pas au besoin cœur. Le déplacement des
specs vers git (2026-08-19) lui retire en plus le volet specs : sans système de fichiers, elle ne voit
plus que la livraison synthétique Confluence, c'est-à-dire une copie datée dont le git fait foi. Il reste
le Q&A sur Jira et la lecture de la synthèse publiée, ce qui ne justifie pas de dupliquer les
instructions.

### Piste 2 - Claude dans Slack (idem)

Même périmètre fonctionnel que la piste 1, sur une surface conversationnelle déjà adoptée. Mêmes angles
morts, désormais sur le code **et** sur les specs, mêmes réserves.

### Piste 3 - Assistant hébergé (cible conditionnelle)

Service central via Claude Agent SDK ou Managed Agents : system prompt dérivé de `CLAUDE.md`, outils
Atlassian plus clones read-only côté serveur (specs et code), front web ou Slack. Couvre tout le périmètre sans
aucune installation côté utilisateur. Nécessite build, hébergement et revue sécu.

À activer si la population dépasse ce que l'install par poste supporte, ou si des profils
zéro-install apparaissent.

Question à trancher à ce moment-là : **identité de service unique** (simple, mais casse la
traçabilité et donne les mêmes droits à tout le monde) contre **OAuth par utilisateur** (droits et
audit natifs, mise en œuvre plus lourde).

### Débloqueurs d'accès au code (transverse)

- **(a) MCP GitLab officiel activé par l'admin.** Non activé au 2026-07-29 sur
  `gitlab.amersports.com` (testé). Endpoint `https://gitlab.amersports.com/api/v4/mcp`, OAuth 2.0,
  prérequis GitLab >= 18.6 et GitLab Duo activé. Bénéficie à **toutes** les pistes : à relancer en
  parallèle, indépendamment de la piste retenue.
- **(b) MCP communautaire + PAT read-only.** Contourne (a), au prix d'un secret à gérer et d'un
  composant non officiel à faire valider.
- **(c) Clones read-only côté serveur.** Ne concerne que la piste 3 : sans système de fichiers, sans
  objet pour les pistes 0, 1 et 2.

## Décisions (2026-07-29, révisées)

- **Distribution non-dev : piste 0**, Claude Code hors VSCode avec bootstrap scripté.
- **Piste 3 : cible conditionnelle**, déclenchée par la montée en volume ou l'apparition de profils
  zéro-install.
- **Pistes 1 et 2 : compléments** pour du Q&A specs, jamais la solution principale. Périmé depuis le
  2026-08-19 : voir la révision ci-dessous, elles ne voient plus les specs.
- **Débloqueur (a)** : à porter auprès de l'admin GitLab en parallèle du pilote.

### Révision du 2026-08-12 : écriture Confluence ouverte (refermée depuis)

Création / mise à jour de page et commentaires Confluence sont passés en `allow` dans
`.claude/settings.json`, pour publier la documentation du projet dans l'espace SMT. Jira et le code
restent en lecture seule stricte, appliquée par des règles `deny`.

Ce que cela coûte : sur Confluence, le garde-fou n'est plus technique mais déclaratif, donc
contournable. La ligne « Garde-fous d'écriture » de la grille ci-dessus ne distingue plus la piste 0
des pistes 1 et 2 sur ce point précis.

Décision reprise le 2026-08-19 : les quatre outils sont revenus en `deny`, voir ci-dessous.

### Révision du 2026-08-19 : les specs passent dans git, Confluence redevient lecture seule

Les spécifications et le glossaire ne sont plus dans Confluence. Ils sont versionnés en markdown dans
<https://gitlab.amersports.com/pdp/smt/sln-smt-spec-owner> (dossier `solution-overview/`), cloné en
lecture seule dans `repos/sln-smt-spec-owner/`. Ce que porte l'espace Confluence `SMT` est désormais une
**version synthétique livrée** par le projet Claude Code du PO : une copie dérivée et datée. En cas
d'écart, le git fait foi.

Trois conséquences :

- **Confluence repasse en lecture seule.** Création / mise à jour de page et commentaires sont revenus en
  `deny` sur les deux serveurs MCP Atlassian. La livraison Confluence appartient au projet du PO, donc cet
  assistant n'a plus de raison d'y écrire, et le garde-fou redevient technique. Le point ouvert « périmètre
  d'écriture Confluence à confirmer » est refermé.
- **Le contrôle de fraîcheur couvre les specs.** Le dépôt de specs est soumis à la même règle fail-fast
  que le code, et le contrôle s'applique **avant toute lecture de spec**, pas seulement avant une
  comparaison spec / code : une règle métier périmée est aussi trompeuse qu'un code périmé, et aussi
  silencieuse. `scripts/bootstrap.ps1` traite les trois dépôts.
- **Les pistes 1 et 2 perdent leur dernier périmètre utile.** Sans système de fichiers, elles ne voient ni
  le code ni les specs. Elles ne sont plus des compléments crédibles, seulement un accès à Jira et à la
  synthèse publiée.

### Ce que cela révise, et pourquoi

La version initiale recommandait la piste 1 à court terme et retenait l'option (c) pour l'accès au
code. Deux incohérences : la piste 1 ne couvre pas le code alors que le code est le cœur du besoin ;
et l'option (c) suppose un runtime doté d'un système de fichiers, donc la piste 3, pas la piste 1.

Le principe « les non-devs ne clonent jamais ce dépôt » excluait par construction la seule option qui
couvre aujourd'hui l'ensemble du périmètre sans rien construire. Il est levé.

## Gouvernance

- Sorties en proposition par défaut. Specs, Jira, Confluence et code sont tous en lecture seule stricte
  (voir `CLAUDE.md`). Une correction de spec est portée par le PO dans son propre projet.
- En piste 0, cette lecture seule est appliquée techniquement : règles `deny` sur les outils d'écriture
  Jira et Confluence, `Edit(repos/**)` et `Write(repos/**)` pour les specs et le code, liste `tools:` du
  sous-agent. Toute autre surface doit documenter explicitement ce qu'elle garantit.
- Ce dépôt fait foi pour les instructions. Toute copie sur une autre surface est datée et
  resynchronisée à chaque évolution, faute de quoi elle dérive en silence.
- Chacun agit sous son identité (OAuth Atlassian et identifiants GitLab personnels) : droits et
  traçabilité natifs. Une identité de service partagée casserait cela et doit être décidée
  explicitement.
- Les **données lues** restent chez Amer Sports : issues dans le tenant Atlassian, specs et code sur
  `gitlab.amersports.com` et dans les clones locaux. Rien n'est recopié ailleurs.
- Les **instructions** sont hébergées sur `gitlab.amersports.com` (`pdp/ai/sln-smt-assistant`), donc
  en interne. Le dépôt ne contient ni secret, ni code, ni PII, mais il expose des éléments internes
  (URL GitLab, chemins des dépôts, nom de l'espace Confluence, structure du projet) : les garder sur
  l'instance interne évite la question de la publication sur une plateforme externe.
- Pas de PII ni de données sensibles dans les sorties ou artefacts.

## Risques et questions ouvertes

- **Publication du dépôt : levée.** `sln-smt-assistant` est publié sur l'instance GitLab interne,
  dans le groupe `pdp/ai` (<https://gitlab.amersports.com/pdp/ai/sln-smt-assistant>, branche `main`).
  L'administration n'est donc pas liée à une personne, et l'hébergement reste dans le périmètre Amer
  Sports. Reste à accorder l'accès nominativement à chaque utilisateur.
- **Fraîcheur des clones.** Traité : le contrôle est décrit dans `CLAUDE.md` (« Fraîcheur des
  clones ») et exigé en prérequis par tous les skills, qui refusent de conclure sur un clone en retard,
  non vérifiable ou modifié. Depuis le 2026-08-19 il couvre aussi le dépôt de specs, avant toute lecture
  de spec.
- **Prérequis à provisionner** par personne : siège Claude, compte GitLab avec accès au projet
  `pdp/ai/sln-smt-assistant`, au dépôt de specs `pdp/smt/sln-smt-spec-owner` et aux deux dépôts de code
  SMT, compte Atlassian. Soit deux authentifications distinctes à l'installation (GitLab, Atlassian), le
  même compte GitLab servant pour l'assistant, les specs et le code. L'accès au dépôt de specs est le
  nouveau point de blocage : sans lui, l'assistant n'a ni specs ni glossaire.
- **Détails à valider en pilote** : approbation du MCP de projet dans l'app desktop, prise en compte
  de `.claude/settings.json` et des skills, disponibilité de l'app sur les postes Amer Sports.
- **Seuil de bascule vers la piste 3** : à partir de combien d'utilisateurs l'install par poste
  devient-elle intenable ? Non défini.

## Prochaines étapes

1. Pilote de la piste 0 sur un poste non-dev, en suivant
   [demarrage-non-dev.md](demarrage-non-dev.md).
2. En parallèle : relance de l'admin GitLab sur le MCP officiel (débloqueur (a)).

Déjà en place : le dépôt publié sur le GitLab interne, `scripts/bootstrap.ps1` (provisionne et contrôle un
poste) et [demarrage-non-dev.md](demarrage-non-dev.md) (guide pas à pas).
