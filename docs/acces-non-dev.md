# Accès des profils non-dev

Note de cadrage. Aucune implémentation à ce stade ; le pilote reste à mener.

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
- le MCP Atlassian, via `.mcp.json` en Claude Code, via un Connecteur sur claude.ai et Slack.

Non portable :

- l'accès à un système de fichiers, donc tout le volet code ;
- les garde-fous read-only **techniques** : les règles `deny` de `.claude/settings.json` et la liste
  `tools:` du sous-agent `code-explorer` n'existent qu'en Claude Code. Ailleurs, le read-only
  redevient déclaratif, c'est-à-dire une consigne que rien n'empêche de contourner ;
- la source unique : hors de ce dépôt, les instructions sont une copie, et une copie dérive.

## Grille de décision

| Critère | Piste 0 Claude Code | Piste 1 claude.ai Project | Piste 2 Slack | Piste 3 hébergé |
|---|---|---|---|---|
| Confluence / Jira | oui | oui | oui | oui |
| Code (`repos/`) | oui | non | non | oui |
| Skills et sous-agent | natifs | à recopier, partiel | à recopier, partiel | à réimplémenter |
| Garde-fous read-only | techniques | déclaratifs | déclaratifs | à construire |
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
non-dev installe l'application, lance un script de bootstrap qui clone ce dépôt puis les deux dépôts
SMT dans `repos/`, s'authentifie une fois sur GitLab (HTTPS) et une fois sur Atlassian (OAuth via
`/mcp`), et chatte.

Il hérite tel quel de `CLAUDE.md`, des 5 skills, de la commande `/explore-code`, du sous-agent
`code-explorer` et des règles `deny`. Rien à reconstruire, rien à resynchroniser : `git pull` suffit.

Limites : une install et un clone par poste ; un siège Claude, un compte GitLab et un compte
Atlassian par personne ; les clones doivent être rafraîchis pour rester fiables.

### Piste 1 - claude.ai Project + Connecteurs (complément)

Instructions du Project recopiées depuis `CLAUDE.md`, connecteur Atlassian déjà en place. Chat
navigateur, zéro installation. Couvre Confluence et Jira.

Rétrogradée : ne couvre pas le code, donc ne répond pas au besoin cœur. Duplique les instructions et
perd les garde-fous techniques. Reste utile pour du Q&A specs pur, jamais comme solution principale.

### Piste 2 - Claude dans Slack (complément)

Même périmètre fonctionnel que la piste 1, sur une surface conversationnelle déjà adoptée. Même angle
mort sur le code, mêmes réserves. Rapide si l'app Slack est déjà déployée dans l'org.

### Piste 3 - Assistant hébergé (cible conditionnelle)

Service central via Claude Agent SDK ou Managed Agents : system prompt dérivé de `CLAUDE.md`, outils
Atlassian plus clones read-only côté serveur, front web ou Slack. Couvre tout le périmètre sans
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
- **Pistes 1 et 2 : compléments** pour du Q&A specs, jamais la solution principale.
- **Débloqueur (a)** : à porter auprès de l'admin GitLab en parallèle du pilote.

### Ce que cela révise, et pourquoi

La version initiale recommandait la piste 1 à court terme et retenait l'option (c) pour l'accès au
code. Deux incohérences : la piste 1 ne couvre pas le code alors que le code est le cœur du besoin ;
et l'option (c) suppose un runtime doté d'un système de fichiers, donc la piste 3, pas la piste 1.

Le principe « les non-devs ne clonent jamais ce dépôt » excluait par construction la seule option qui
couvre aujourd'hui l'ensemble du périmètre sans rien construire. Il est levé.

## Gouvernance

- Accès en lecture seule, sorties en proposition. Aucune écriture Confluence, Jira ou code.
- En piste 0, le read-only est **appliqué techniquement** (règles `deny`, liste `tools:` du
  sous-agent). Toute autre surface doit documenter explicitement comment elle le garantit, ou assumer
  qu'il n'est que déclaratif.
- Ce dépôt fait foi pour les instructions. Toute copie sur une autre surface est datée et
  resynchronisée à chaque évolution, faute de quoi elle dérive en silence.
- Chacun agit sous son identité (OAuth Atlassian et identifiants GitLab personnels) : droits et
  traçabilité natifs. Une identité de service partagée casserait cela et doit être décidée
  explicitement.
- Données dans le tenant Amer Sports. Pas de PII ni de données sensibles dans les sorties ou
  artefacts.

## Risques et questions ouvertes

- **Bloquant : ce dépôt n'est publié nulle part.** `sln-smt-assistant` n'a aucun remote git ; il
  n'existe que sur le poste de l'architecte. Personne ne peut donc le récupérer, ce qui bloque la
  piste 0 à sa toute première étape. À créer sur `gitlab.amersports.com`, à côté des dépôts SMT, puis
  à pousser. Prérequis à tout pilote.
- **Fraîcheur des clones.** Traité : le contrôle est décrit dans `CLAUDE.md` (« Fraîcheur des
  clones ») et exigé en prérequis par `spec-vs-code`, `doc-freshness` et `refactor-proposal`, qui
  refusent désormais de conclure sur un clone en retard, non vérifiable ou modifié.
- **Prérequis à provisionner** par personne : siège Claude, compte GitLab avec accès aux deux dépôts,
  compte Atlassian.
- **Détails à valider en pilote** : approbation du MCP de projet dans l'app desktop, prise en compte
  de `.claude/settings.json` et des skills, disponibilité de l'app sur les postes Amer Sports.
- **Seuil de bascule vers la piste 3** : à partir de combien d'utilisateurs l'install par poste
  devient-elle intenable ? Non défini.

## Prochaines étapes

1. **Publier ce dépôt sur GitLab.** Bloquant : sans cela, rien d'autre n'est possible.
2. Pilote de la piste 0 sur un poste non-dev, en suivant
   [demarrage-non-dev.md](demarrage-non-dev.md).
3. En parallèle : relance de l'admin GitLab sur le MCP officiel (débloqueur (a)).

Outillage déjà en place pour le pilote : `scripts/bootstrap.ps1` (provisionne et contrôle un poste)
et [demarrage-non-dev.md](demarrage-non-dev.md) (guide pas à pas).
