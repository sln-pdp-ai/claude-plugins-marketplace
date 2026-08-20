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
| `smt-spec-quality` | spec owner, PO, toute personne qui relit une spec | skills `policy`, `term-check`, `spec-readiness` |
| `smt-code-crosscheck` | profils techniques | skills `policy`, `spec-vs-code`, `doc-freshness`, `refactor-proposal`, `explore-code` + sous-agent `code-explorer` |

Deux plugins et non un seul : le spec owner n'a ni accès au code ni besoin de Jira, et son propre
`CLAUDE.md` interdit à son projet de dépendre du code. Lui livrer les skills de code l'obligerait à
hériter d'outils qu'il n'a pas le droit d'utiliser.

Installation, une fois les droits GitLab accordés :

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install smt-spec-quality@pdp-ai
```

Variante sans commande : déclarer `extraKnownMarketplaces` et `enabledPlugins` dans le
`.claude/settings.json` du dépôt cible (corpus de specs, backend, console). Le marketplace s'ajoute dès
que la personne fait confiance au dossier. Cela suppose de commiter dans ces dépôts, donc l'accord de
leurs owners.

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
permanence, sur une saleté que le plugin aurait lui-même créée.

Trois actions : `-Action paths` (aucun réseau), `-Action check` (fetch + verdict, code de retour 1 si un
dépôt bloque), `-Action ensure` (clone ce qui manque). Verdicts : `A_JOUR`, `EN_RETARD`, `FETCH_KO`,
`SALE`, `ABSENT`.

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
- **La mise à jour d'une copie de travail périmée reste manuelle.** `-Action ensure` clone ce qui manque
  mais ne rafraîchit rien, par principe de lecture seule. L'utilisateur doit lancer lui-même un
  `git -C <chemin> pull --ff-only`. Pour un profil non-dev, c'est la seule commande git qu'il reste à
  taper : une action `-Action update` explicite, ou une invite plus précise dans le message de fail-fast,
  lèverait ce point.
- **Deux plugins actifs en même temps** injectent deux fois la doctrine au démarrage, évaluent deux fois
  chaque écriture, et déclarent deux serveurs MCP Atlassian équivalents. Sans effet fonctionnel, mais du
  contexte et une authentification en double.
- **Le MCP Atlassian se voyage, pas son authentification.** Chaque utilisateur passe par `/mcp` une
  fois. Tant qu'il ne l'a pas fait, les skills restent utilisables sur les fichiers du corpus, mais pas
  sur une clé Jira.
- **Le corpus n'est pas embarqué** dans les plugins, volontairement : ce serait une troisième copie des
  specs, qui dériverait en silence entre deux mises à jour, alors que la règle du projet est que le git
  fait foi.
