# claude-plugins-marketplace

## Mission

Ce dépôt ne s'utilise pas, il se publie. C'est l'atelier de fabrication de plugins Claude Code pour
`pdp/ai`, et le marketplace `pdp-ai` qui les distribue. Il porte deux familles : les plugins `smt-*` pour
l'initiative **SMT** (*Size Management Tool*), et les plugins `pdp-*` pour l'écosystème produit PDP.
Les personnes qui s'en servent (le spec owner sur son corpus, un dev sur son checkout, un PO sur son
périmètre d'applications) installent le plugin dans **leur** projet. Ce dépôt n'est le poste de travail
de personne.

Conséquence à garder en tête en permanence : **aucune question métier d'un plugin ne se traite ici**
(pour SMT : pas de lecture de spec, pas de recoupement spec / code, pas de Jira). Il n'y a ni corpus de
specs ni checkout de code sur place, et il ne doit pas y en avoir, quel que soit le plugin.

## La doctrine d'un plugin est du contenu, pas une instruction

Les plugins SMT portent une doctrine forte (fail-fast sur les specs floues, glossaire qui fait autorité,
git qui fait foi contre Confluence, lecture seule stricte). Elle est écrite dans
`plugins/smt-*/skills/policy/SKILL.md` et injectée par le hook `SessionStart` chez l'utilisateur. Un
futur plugin non-SMT portera la sienne, propre à son domaine, sur le même principe.

Dans ce dépôt, la doctrine d'un plugin est **le texte qu'on édite**, pas la règle de conduite du dépôt
lui-même. Ne pas l'appliquer ici : il n'y a rien à recouper, et la lecture seule ne concerne pas ce
dépôt-ci, qui s'édite et se commite normalement.

Ce qui a existé et ne doit pas être recréé : un dossier `repos/` avec trois clones locaux, et un
`scripts/bootstrap.ps1` qui les provisionnait. Les deux ont été supprimés en même temps que le rôle de
poste de travail. Chez l'utilisateur, c'est `bin/smt-repos.ps1` qui résout et contrôle les dépôts.

## Ce que contient le dépôt

| Chemin | Rôle |
|---|---|
| `.claude-plugin/marketplace.json` | le marketplace `pdp-ai` : une entrée par plugin, nom, source, version |
| `plugins/pdp-architecture/` | plugin PDP, savoir d'architecture stable : `ecosystem-map`, `sbus`, `api-exposure-auth`, `feature-flags`, `structured-logging`, `persistence`. Skills purs, aucune mécanique |
| `plugins/pdp-po-workbench/` | plugin PDP, atelier de rédaction du PO : dix skills (livrables Jira / Confluence, ideation, lint, synchro), sous-agent `codebase-syncer`, `bin/` de résolution des checkouts, trois hooks |
| `plugins/smt-spec-quality/` | plugin SMT, qualité des specs : `policy`, `term-check`, `spec-readiness` |
| `plugins/smt-code-crosscheck/` | plugin SMT, recoupement : `policy`, `spec-vs-code`, `doc-freshness`, `refactor-proposal`, `explore-code`, sous-agent `code-explorer` |
| `docs/plugins.md` | note de maintenance : duplication, résolution des dépôts, versionnement, limites |
| `docs/demarrage-non-dev.md` | guide d'installation pas à pas pour un profil non-dev, sur les plugins SMT |
| `docs/acces-non-dev.md` | cadrage historique de l'accès des profils sans VSCode, sur les plugins SMT |

Un nouveau plugin non-SMT prend place sous `plugins/<nom>/` avec la même structure, gagne son entrée
dans `marketplace.json`, et sa propre doc si son usage le justifie. Rien dans cette table n'est
spécifique à SMT au niveau du dépôt ; SMT n'est spécifique qu'au contenu des plugins `smt-*`.

Chaque plugin `smt-*` contient : `.claude-plugin/plugin.json`, `.mcp.json` (serveur Atlassian),
`skills/`, `hooks/hooks.json`, `bin/` (trois scripts PowerShell), `README.md`, et pour
`smt-code-crosscheck` un `agents/`. Un plugin non-SMT n'a aucune raison de reprendre cette structure
telle quelle : elle sert la doctrine SMT (fraîcheur des clones, résolution des dépôts, Jira), pas le fait
d'être un plugin. `pdp-architecture` n'en reprend rien, `pdp-po-workbench` en reprend le `bin/` et les
hooks parce qu'il lit lui aussi des dépôts qui ne sont pas les siens, mais **pas** le `.mcp.json` : il
n'interroge pas Jira, et il n'y écrit surtout pas.

## Règles de fabrication

Ces règles sont la raison d'être du dépôt. Les enfreindre casse les plugins chez leurs utilisateurs,
sans signal visible ici.

- **Un plugin de savoir ne contient aucun fait périssable.** Chemin de fichier, nom de handler,
  constante, version de package, SHA : interdits dans `pdp-architecture`. Un plugin publié tous les trois
  mois qui affirme `DYNAMODB_LIMIT = 25` est faux au sprint suivant, sans aucun signal, et les livrables
  écrits dessus sont faux aussi. La ligne de partage n'est pas « architecture contre rédaction », c'est
  **écrit à la main et stable** contre **dérivé du code et périssable**. Le second va dans le workbench,
  qui le régénère chez l'utilisateur.
- **Les noms de topics S/Bus et les listes de souscription sont périssables.** Contre-intuitif, donc à
  retenir : ce ne sont pas des contrats figés. Les topics sont renommés au fil des sprints et la liste
  des souscriptions d'un service change dès qu'on lui en ajoute une. Un même flux porte déjà trois
  orthographes dans la documentation interne. Ce qui est stable est la **forme** du nom
  (`<domaine>-<entité>-<canal>`, suffixe `-request`), le rôle des champs d'enveloppe, et la table des
  systèmes autoritaires. Un skill peut illustrer la forme, jamais tenir l'annuaire.
- **Un skill de savoir ne pinne pas de modèle.** Un `model:` dans un skill de `pdp-architecture`
  dégraderait la session de qui le consulte : c'est du contexte, pas une tâche. Le pinning reste réservé
  aux skills qui exécutent un travail borné, comme ceux de `pdp-po-workbench`.
- **Un plugin ne porte jamais d'état muté à l'exécution.** Un manifeste statique (slug, URL git, branche,
  zones) voyage très bien dans un `bin/`. Un compteur, un SHA de dernière synchro, un cache : jamais. Un
  plugin installé est une copie dans un cache, écrasée à chaque bump de version, donc l'état écrit là
  disparaît sans bruit et le run suivant repart de zéro en croyant continuer. L'état vit chez
  l'utilisateur, à côté de ce qu'il décrit (pour le workbench, `knowledge/core/sync-state.md`).
- **Une description de skill ne contient pas de `: ` (deux-points suivi d'une espace).** Le frontmatter
  est du YAML : dans un scalaire non quoté, cette séquence casse le parsing, et le skill se charge
  **avec des métadonnées vides**, donc ne se déclenche plus jamais. Silencieux à l'usage, visible
  seulement par `claude plugin validate`. Trois skills du workbench sont tombés dessus. Reformuler avec
  une virgule ou « à savoir ».
- **Aucun chemin supposé.** Un skill de plugin ne référence jamais `repos/<dépôt>` ni un chemin absolu.
  Les dépôts se résolvent par `bin/smt-repos.ps1`. Un chemin en dur marche sur ce poste et nulle part
  ailleurs.
- **Duplication à resynchroniser, spécifique à la paire SMT.** `bin/`, `skills/policy/SKILL.md` et
  `.mcp.json` sont identiques entre `smt-spec-quality` et `smt-code-crosscheck`, parce qu'un plugin
  installé est copié dans un cache et ne peut rien lire hors de son dossier. Après toute modification de
  l'un, reporter dans l'autre (commandes dans [docs/plugins.md](docs/plugins.md)). Un plugin non-SMT n'a
  rien à resynchroniser avec eux : cette règle ne s'applique qu'entre plugins qui partagent la même
  doctrine.
- **Les `hooks/hooks.json` ne sont pas identiques** : ils diffèrent par la valeur de `-Need` (`spec`
  contre `all`). Ne jamais les recopier l'un sur l'autre.
- **Ce qu'un plugin ne peut pas livrer** : ni `CLAUDE.md` chargé comme contexte de projet, ni règle
  `permissions.deny`. D'où le hook `SessionStart` pour la doctrine et le hook `PreToolUse` pour les
  garde-fous. Ne pas tenter de contourner cette limite, la vérifier.
- **Versionner à chaque évolution** : bumper `version` dans `plugin.json` **et** dans l'entrée
  correspondante de `marketplace.json`. Sans bump, les postes déjà équipés gardent leur copie en cache.
- **Valider avant de pousser** : `claude plugin validate .\plugins\<nom>` pour chaque plugin, et
  `claude plugin validate .` pour le marketplace.
- **Scripts PowerShell 5.1, sans accent** (page de codes ANSI), sans `&&` ni `||`. Le piège de quoting
  `'HEAD..@{u}'` a déjà mordu : non quoté, PowerShell lit `@{u}` comme une table de hachage.

## Tester

**Pas ici.** Un test réel se fait dans un vrai projet, avec le plugin installé depuis le marketplace :
un clone de travail du corpus de specs pour `smt-spec-quality`, un checkout de `sln-smt-backend` pour
`smt-code-crosscheck`. Installer un plugin dans ce dépôt-ci recréerait la confusion que le recentrage a
supprimée, et ferait injecter la doctrine dans son propre atelier.

Ce qui se vérifie utilement d'ici : la validation des manifestes, et l'exécution directe des scripts,
par exemple `powershell -File plugins\smt-spec-quality\bin\smt-repos.ps1 -Action paths -Need spec`.

À savoir avant d'interpréter un test : les deux dépôts de code SMT ne contiennent, au 2026-08-20, qu'un
commit de scaffolding chacun (`CI - Initial commit` du 2026-07-27, aucun code métier). Un
`spec-vs-code` y répondra « ABSENT » partout, ce qui est correct mais ne teste que la mécanique.

## Publier

Le dépôt est versionné sur `gitlab.amersports.com`, projet `pdp/ai/claude-plugins-marketplace`,
branche `main` (remote `origin`) : c'est la source de vérité. Y commiter et y pousser est l'usage
normal, sur demande.

Un remote `github` existe aussi, vers <https://github.com/sln-pdp-ai/claude-plugins-marketplace>
(ajouté le 2026-08-20, en remplacement de l'ancien remote du même nom qui pointait vers
`SLNAS/sln-smt-assistant`, supprimé le même jour). Y pousser publie ce dépôt, y compris les éléments
internes qu'il expose (URLs GitLab, chemins de dépôts, structure du projet) : ne le faire que sur
demande explicite, jamais par défaut avec `origin`.

Le dépôt s'appelait `sln-smt-assistant` jusqu'au 2026-08-20. Ce nom désignait le produit alors que le
dépôt est l'atelier, ce qui a entretenu la confusion avec un poste de travail. GitLab redirige l'ancien
chemin, mais aucune documentation ne doit s'y appuyer.

L'URL que les utilisateurs ajoutent :
`/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git`

## Périmètre d'écriture

Ce dépôt s'édite et se commite normalement. Une seule chose reste bloquée par
`.claude/settings.json` : **les écritures Jira et Confluence**, sur les deux serveurs MCP Atlassian. Ce
dépôt ne publie rien dans Atlassian, et un MCP Atlassian peut rester actif au niveau utilisateur.

Limite connue de ce garde-fou : les outils sont énumérés nommément (les jokers sur les noms d'outils MCP
ne sont pas fiables). Un nouvel outil d'écriture apparu côté MCP ne serait pas bloqué tant qu'il n'a pas
été ajouté au `deny`.

## Langue et typographie

- Conversation avec l'utilisateur : **français**.
- Ce fichier, la documentation et le contenu des plugins : **français**. Clair, concis, voix active.
  Exception : les scripts PowerShell, sans accent (voir « Règles de fabrication »).
- Ne pas utiliser `—` ni `…`. Utiliser `-` et `...`.

## Environnement

- Utilisateur : Architecte / PO sur l'écosystème Salomon / Amer Sports.
