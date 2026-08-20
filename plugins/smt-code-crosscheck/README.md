# smt-code-crosscheck

Recoupement spec / code SMT. Destiné aux profils techniques : écarts entre la spec et le code, détection
d'une spec périmée face au code, propositions de refactoring, exploration de code en lecture seule.

## Installation

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/sln-smt-assistant.git
/plugin install smt-code-crosscheck@sln-smt
```

Si l'installation annonce `Run /reload-plugins to activate`, lancer `/reload-plugins`.

## Ce que le plugin apporte

| Élément | Invocation | Rôle |
|---|---|---|
| `policy` (skill) | automatique, ou `/smt-code-crosscheck:policy` | Doctrine SMT : fail-fast, glossaire, sources de vérité, résolution des dépôts, fraîcheur |
| `spec-vs-code` (skill) | `/smt-code-crosscheck:spec-vs-code <cible>` | Écarts entre la spec et le code |
| `doc-freshness` (skill) | `/smt-code-crosscheck:doc-freshness <fichier de spec>` | Ce que le code contredit dans une spec |
| `refactor-proposal` (skill) | `/smt-code-crosscheck:refactor-proposal <zone>` | Propositions de refactoring, non appliquées |
| `explore-code` (skill) | `/smt-code-crosscheck:explore-code <question>` | Exploration déléguée, synthèse `fichier:ligne` |
| `code-explorer` (sous-agent) | délégation | Lecture seule du code : Read, Grep, Glob uniquement |

Un hook `SessionStart` injecte la doctrine et l'état des trois dépôts. Un hook `PreToolUse` bloque les
écritures Jira et Confluence, ainsi que les écritures dans les dépôts lus comme sources externes.

## Jira : à authentifier une fois

Le plugin livre le serveur MCP Atlassian, nécessaire pour partir d'une story
(`/smt-code-crosscheck:spec-vs-code SMT-123`) plutôt que d'un fichier de spec. Authentification OAuth,
par utilisateur, au premier usage :

```
/mcp
```
Sélectionner le serveur `atlassian` du plugin, puis s'authentifier dans le navigateur avec son compte
Atlassian Amer Sports. Les jetons restent locaux.

Sans cette étape, les skills fonctionnent sur les fichiers du corpus et le code, mais pas sur une clé
Jira. Un serveur `atlassian` déjà présent sur le poste n'est pas remplacé : les deux cohabitent.

Le plugin reste en **lecture seule** sur Jira : les outils d'écriture sont bloqués par le hook, quel que
soit le serveur qui les expose.

## Ce dont il a besoin

Trois dépôts, résolus indépendamment les uns des autres, dans cet ordre : variable d'environnement
(`SMT_SPEC_DIR`, `SMT_BACKEND_DIR`, `SMT_CONSOLE_DIR`), projet courant, `repos/<nom>`, dépôt frère,
clone de travail dans `.smt-tmp/`.

En pratique, pour un dev qui travaille dans son checkout `sln-smt-backend` : le backend est le projet
courant, et le corpus de specs plus la console sont clonés en copie de travail au premier usage, après
annonce. Voir le README de `smt-spec-quality` pour le détail du dossier `.smt-tmp/` et de son
alternative.

État courant, à tout moment :

```
powershell -File "<dossier du plugin>/bin/smt-repos.ps1" -Action check -Need all
```

## Limites connues

- **Windows.** Scripts en PowerShell 5.1 ; hors Windows, les hooks et le contrôle de fraîcheur ne
  s'exécutent pas.
- **Le code que vous éditez chez vous n'est pas protégé**, et c'est voulu : le hook ne bloque que les
  dépôts résolus comme sources externes, pas le projet courant. Les sorties des skills restent des
  propositions.
- **Pas d'état de déploiement.** Le MCP GitLab n'est pas activé sur `gitlab.amersports.com` : ni
  pipelines, ni environnements. Ne rien inventer là-dessus.
- **Écritures Atlassian** bloquées tant que le plugin est actif ; échappatoire assumée
  `SMT_ALLOW_ATLASSIAN_WRITES=1`.
