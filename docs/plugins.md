# Distribution en plugins (marketplace interne)

Comment l'outillage SMT est publié pour les personnes qui l'utilisent : le spec owner sur son corpus, un
dev dans son checkout de code. Note de maintenance ; l'usage côté utilisateur est dans les `README.md`
des plugins.

Ce dépôt ne sert plus qu'à ça. Il n'est le poste de travail de personne : ni corpus de specs, ni
checkout de code, ni `repos/`, ni script de provisionnement. Voir [../CLAUDE.md](../CLAUDE.md).

## Ce qui est publié

Ce dépôt **est** le marketplace. `.claude-plugin/marketplace.json` à la racine, un dossier par plugin
sous `plugins/`.

| Plugin | Pour qui | Contenu |
|---|---|---|
| `pdp-architecture` | PO **et** dev du domaine PDP | skills `ecosystem-map`, `sbus`, `api-exposure-auth`, `feature-flags`, `structured-logging`, `persistence`. Skills purs : ni `bin/`, ni hook, ni `.mcp.json`, ni sous-agent |
| `smt-spec-quality` | spec owner, PO, toute personne qui relit une spec | skills `policy`, `term-check`, `spec-readiness` |
| `smt-code-crosscheck` | profils techniques | skills `policy`, `spec-vs-code`, `doc-freshness`, `refactor-proposal`, `explore-code` + sous-agent `code-explorer` |

Deux plugins et non un seul : le spec owner n'a pas accès au code, et son propre `CLAUDE.md` interdit à
son projet d'en dépendre. Lui livrer les skills de code l'obligerait à hériter d'outils qu'il n'a pas le
droit d'utiliser. Jira, lui, est nécessaire aux deux : chaque plugin embarque son propre `.mcp.json`
Atlassian pour pouvoir cibler une story plutôt qu'un seul fichier.

Installation, une fois les droits GitLab accordés :

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install smt-spec-quality@pdp-ai
```

Variante sans commande : déclarer `extraKnownMarketplaces` et `enabledPlugins` dans le
`.claude/settings.json` du dépôt cible (corpus de specs, backend, console). Le marketplace s'ajoute dès
que la personne fait confiance au dossier. Cela suppose de commiter dans ces dépôts, donc l'accord de
leurs owners.

## La famille `pdp-*` et sa ligne de partage

Les plugins `pdp-*` distribuent l'outillage du domaine PDP, issu du dépôt
`archi-user-stories-assistant` (base de connaissance de l'architecte / PO sur l'écosystème produit).
Ce dépôt-là reste en place, inchangé ; les plugins en sont l'extraction publiable.

Trois plugins visés, découpés sur la **volatilité du contenu**, pas sur la fonction :

| Plugin | Contenu | Cadence | PO | Dev |
|---|---|---|---|---|
| `pdp-architecture` | écrit à la main, stable : conventions, invariants, sémantique, vocabulaire, schémas | trimestre | oui | oui |
| `pdp-po-workbench` | rédaction des livrables Jira / Confluence, plus la mécanique qui régénère le savoir périssable chez l'utilisateur | sprint | oui | non |
| `pdp-code-crosscheck` (pas encore écrit) | lecture du code des autres services du domaine, sur le patron de `smt-code-crosscheck` | sprint | non | oui |

Pourquoi cette ligne et pas « architecture d'un côté, stories de l'autre » : les deux phrases « un topic
`-request` déclenche un rejeu sur le topic standard » et « tel handler pagine par 10 » sont toutes les
deux de l'architecture. La première tient des années, la seconde quelques semaines. Publier la seconde
dans un plugin trimestriel la rend fausse en silence, et rend fausses les stories écrites dessus. Un
plugin `pdp-architecture` qui descend au chemin de fichier pourrit sans que personne ne le voie.

Conséquence de conception : `pdp-po-workbench` clone les dépôts du périmètre du PO dans `./local-repos`
de son projet (ignoré par git) et y lance une synchronisation, qui produit chez lui un `knowledge/`
restreint et à jour. Ce `knowledge/` local est la seule source légitime des faits périssables.

Deux règles à honorer dès maintenant, parce qu'elles sont gratuites au départ et coûteuses ensuite :

- La mécanique de checkout et de synchronisation de `pdp-po-workbench` est un `bin/` **autonome**, sur le
  modèle de `bin/smt-repos.ps1`, jamais de la prose diluée dans un `SKILL.md` de rédaction. Le jour où
  `pdp-code-crosscheck` arrive, il en copie le dossier, duplication assumée comme entre les deux `smt-*`.
- Le manifeste des dépôts (slug, URL git, branche, zones à scanner) vit dans **`pdp-po-workbench`**, pas
  dans `pdp-architecture`. Un plugin installé ne lit rien hors de son dossier : `pdp-architecture` porte
  la carte éditoriale des applications, le workbench porte la donnée opérationnelle qui lui sert à
  l'exécution. Les deux peuvent dériver, la dérive est bénigne.

`pdp-architecture` n'a ni script, ni hook, ni serveur MCP, donc il fonctionne aussi sur macOS et Linux,
contrairement aux plugins `smt-*`.

## Ce qui ne voyage pas dans un plugin, et comment c'est compensé

| Élément du projet | Voyage ? | Compensation |
|---|---|---|
| Skills, sous-agent | oui | tels quels |
| `.mcp.json` (serveur Atlassian) | oui | un `.mcp.json` par plugin, identique à celui de ce dépôt. Indispensable : sans lui, les skills réclament une story Jira qu'ils ne peuvent pas lire. L'authentification reste OAuth par utilisateur (`/mcp`) |
| `CLAUDE.md` | non, un `CLAUDE.md` de plugin n'est pas chargé comme contexte de projet | noyau injecté par le hook `SessionStart`, détail dans le skill `policy` |
| `permissions.deny` | non, un plugin ne peut livrer que les clés `agent` et `subagentStatusLine` de `settings.json` | hook `PreToolUse` qui sort en code 2 (blocage inconditionnel, message rendu au modèle) |
| Les dépôts eux-mêmes (corpus, code) | non | résolution dynamique, clone de travail à la demande |
| Chemins de dépôt en dur | interdits | `bin/smt-repos.ps1`, voir ci-dessous |

## Résolution des dépôts

Aucun chemin n'est supposé. `bin/smt-repos.ps1` résout chaque dépôt indépendamment, dans cet ordre :
variable d'environnement dédiée, projet courant s'il **est** le dépôt, `repos/<nom>`, dépôt frère
`../<nom>`, clone de travail. Un dépôt n'est reconnu que s'il porte sa marque : `solution-overview/glossary.md`
pour le corpus, l'URL du remote `origin` pour les dépôts de code. Un dossier vide au bon nom n'est pas le
dépôt.

Le clone de travail va dans `.smt-tmp/` du projet courant, **à condition que git l'ignore**. Sinon il
part dans `%LOCALAPPDATA%\smt-assistant\repos`. Sans cette condition, le plugin salirait le working tree
d'un dépôt qu'il est censé ne pas toucher, et le verdict de fraîcheur `SALE` se déclencherait en
permanence, sur une saleté que le plugin aurait lui-même créée. Quand ce cas se présente (le projet
ouvert est lui-même un dépôt git qui n'ignore pas `.smt-tmp`), `-Action paths` et `-Action check` le
signalent, et la doctrine propose d'ajouter `.smt-tmp/` au `.gitignore` du projet avant de cloner : une
édition proposée à l'utilisateur, pas une correction silencieuse.

Quatre actions : `-Action paths` (aucun réseau), `-Action check` (fetch + verdict, code de retour 1 si
un dépôt bloque), `-Action ensure` (clone ce qui manque), `-Action update` (rafraîchit, `git pull
--ff-only`, les seuls clones de travail gérés par le plugin ; un dépôt géré par l'utilisateur n'est
jamais touché). Verdicts : `A_JOUR`, `EN_RETARD`, `FETCH_KO`, `SALE`, `ABSENT`.

## Ce que le hook PreToolUse bloque, et ce qu'il laisse passer

Bloqué : les outils d'écriture Jira et Confluence des deux serveurs MCP Atlassian ; toute écriture
visant un dépôt résolu comme **source externe**.

Laissé passer, volontairement : les écritures dans le projet courant de la personne. Le spec owner doit
pouvoir rédiger ses specs chez lui, un dev écrire son code chez lui. Conséquence à assumer : chez eux,
la lecture seule des skills redevient déclarative. Le hook protège les copies gérées par le plugin, pas
le poste de travail.

Échappatoire pour les écritures Atlassian, pour qui a d'autres usages de Jira dans la même session :
`SMT_ALLOW_ATLASSIAN_WRITES=1`.

## Duplication assumée entre les deux plugins

`bin/`, `skills/policy/` et `.mcp.json` sont identiques dans les deux plugins. Ce n'est pas un oubli : un
plugin installé est copié dans un cache et **ne peut pas lire de fichier hors de son propre dossier**,
donc aucun dossier partagé n'est possible. La duplication est dans un seul dépôt, commitée et relue d'un
bloc, ce qui n'a rien à voir avec une copie sur une autre surface.

Après toute modification de `bin/` ou de `skills/policy/` dans un plugin :

```powershell
$src = 'plugins\smt-spec-quality'; $dst = 'plugins\smt-code-crosscheck'
Copy-Item "$src\bin\*" "$dst\bin\" -Force
Copy-Item "$src\skills\policy\SKILL.md" "$dst\skills\policy\SKILL.md" -Force
Copy-Item "$src\.mcp.json" "$dst\.mcp.json" -Force
```

Les `hooks/hooks.json` ne sont **pas** identiques : ils diffèrent par la valeur de `-Need` (`spec` contre
`all`). Ne pas les recopier l'un sur l'autre.

## Versionner et tester

- Bumper `version` dans `plugin.json` **et** dans l'entrée correspondante de `marketplace.json` à chaque
  évolution : sans bump, les postes déjà installés gardent leur copie en cache.
- `claude plugin validate .\plugins\<nom>` avant de pousser, et `claude plugin validate .` pour le
  marketplace.
- **Le test réel se fait dans un vrai projet**, jamais dans cet atelier : un clone de travail du corpus
  pour `smt-spec-quality`, un checkout de `sln-smt-backend` pour `smt-code-crosscheck`. Depuis un tel
  dossier, `claude --plugin-dir <chemin absolu du plugin>` évite de passer par le marketplace, et
  `/reload-plugins` recharge après chaque modification.
- Les scripts se testent seuls, hors Claude Code :
  `powershell -File plugins\smt-spec-quality\bin\smt-repos.ps1 -Action check -Need all`.

## Limites connues

- **Windows uniquement** pour les scripts (PowerShell 5.1). Hors Windows, les hooks ne s'exécutent pas :
  ni doctrine injectée, ni garde-fou, ni contrôle de fraîcheur automatique. Un jumeau POSIX des trois
  scripts lèverait la limite.
- **Le blocage Atlassian est actif pour toute la session** dès que le plugin est activé, pas seulement
  pendant l'usage d'un skill SMT. Un hook n'a aucune notion de « quel skill est en cours ».
- **`git commit` n'est pas bloquable par répertoire** : la protection porte sur `Edit` / `Write`.
- **Le rafraîchissement d'un clone de travail périmé passe par l'agent, pas par l'utilisateur.**
  `-Action update` fait le `git pull --ff-only` ; la doctrine (`policy/SKILL.md`) demande de le proposer
  puis de l'exécuter dès que l'utilisateur autorise l'appel d'outil, via le prompt de permission standard
  de Claude Code. Aucune commande à taper. Cela ne s'applique qu'aux clones gérés par le plugin (`.smt-
  tmp/` ou cache utilisateur) : un dépôt que l'utilisateur gère lui-même (projet courant, `repos/<nom>`,
  dépôt frère, variable d'environnement) n'est jamais rafraîchi à sa place, `-Action update` le signale
  et s'arrête là.
- **Deux plugins actifs en même temps** injectent deux fois la doctrine au démarrage, évaluent deux fois
  chaque écriture, et déclarent deux serveurs MCP Atlassian équivalents. Sans effet fonctionnel, mais du
  contexte et une authentification en double.
- **Le MCP Atlassian se voyage, pas son authentification.** Chaque utilisateur passe par `/mcp` une
  fois. Tant qu'il ne l'a pas fait, les skills restent utilisables sur les fichiers du corpus, mais pas
  sur une clé Jira.
- **Le corpus n'est pas embarqué** dans les plugins, volontairement : ce serait une troisième copie des
  specs, qui dériverait en silence entre deux mises à jour, alors que la règle du projet est que le git
  fait foi.
