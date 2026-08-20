# smt-spec-quality

Qualité des spécifications SMT, sans dépendance au code. Destiné à qui rédige ou relit les specs :
cohérence des termes avec le glossaire, et check-list fail-fast « prêt pour le dev ».

## Installation

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install smt-spec-quality@pdp-ai
```

Si l'installation annonce `Run /reload-plugins to activate`, lancer `/reload-plugins`.

## Ce que le plugin apporte

| Skill | Invocation | Rôle |
|---|---|---|
| `policy` | automatique, ou `/smt-spec-quality:policy` | Doctrine SMT : fail-fast, glossaire, sources de vérité, résolution des dépôts, fraîcheur |
| `term-check` | `/smt-spec-quality:term-check <cible>` | Cohérence des termes avec le glossaire |
| `spec-readiness` | `/smt-spec-quality:spec-readiness <cible>` | Verdict PRÊT / PAS PRÊT avec bloquants |

Un hook `SessionStart` injecte la doctrine et l'état des dépôts au démarrage de chaque session. Un hook
`PreToolUse` bloque les écritures Jira et Confluence, ainsi que toute écriture dans un corpus que le
plugin lit comme source externe.

## Jira : à authentifier une fois

Le plugin livre le serveur MCP Atlassian, nécessaire pour cibler une story plutôt qu'un fichier
(`/smt-spec-quality:term-check SMT-123`). Authentification OAuth, par utilisateur, au premier usage :

```
/mcp
```
Sélectionner le serveur `atlassian` du plugin, puis s'authentifier dans le navigateur avec son compte
Atlassian Amer Sports. Les jetons restent locaux.

Sans cette étape, les skills fonctionnent sur les fichiers du corpus, mais pas sur une clé Jira. Si un
serveur `atlassian` est déjà configuré sur le poste, celui du plugin s'y ajoute sans le remplacer : deux
serveurs équivalents cohabitent, sans gêne fonctionnelle.

Le plugin reste en **lecture seule** sur Jira : les outils d'écriture sont bloqués par le hook, quel que
soit le serveur qui les expose.

## Où le plugin cherche le corpus de specs

Dans cet ordre, le premier trouvé gagne :

1. la variable d'environnement `SMT_SPEC_DIR` ;
2. le projet courant, s'il **est** le dépôt `sln-smt-spec-owner` (cas du spec owner : rien à installer) ;
3. `repos/sln-smt-spec-owner` sous le projet courant ;
4. un dépôt frère `../sln-smt-spec-owner` ;
5. un clone de travail dans `.smt-tmp/` du projet courant.

Un dépôt n'est reconnu que s'il porte `solution-overview/glossary.md` : un dossier vide au bon nom n'est
pas le corpus.

Pour le cas 5, le dossier `.smt-tmp/` n'est utilisé que **si git l'ignore**, faute de quoi le plugin
salirait le working tree d'un dépôt qu'il n'est pas censé toucher. Sinon, le clone va dans
`%LOCALAPPDATA%\smt-assistant\repos`. Pour préférer le dossier local, ajouter `.smt-tmp/` à son
`.gitignore` global :

```powershell
git config --global core.excludesfile "$HOME/.gitignore_global"
Add-Content -Path "$HOME/.gitignore_global" -Value '.smt-tmp/' -Encoding utf8
```

Vérifier la résolution à tout moment :

```
powershell -File "<dossier du plugin>/bin/smt-repos.ps1" -Action paths -Need spec
```

## Limites connues

- **Windows.** Les scripts sont en PowerShell 5.1. Sur macOS ou Linux, les hooks et le contrôle de
  fraîcheur ne s'exécuteront pas ; les skills, eux, fonctionnent, mais sans garde-fou ni vérification
  automatique de fraîcheur.
- **Accès GitLab requis.** Le plugin lit un corpus versionné : sans droits sur
  `pdp/smt/sln-smt-spec-owner` et sans VPN, il s'arrête au lieu de conclure.
- **Écritures Atlassian.** Le blocage est session-wide tant que le plugin est actif. Échappatoire
  assumée pour qui a d'autres usages de Jira : `SMT_ALLOW_ATLASSIAN_WRITES=1`.
- **Un `git commit` ne peut pas être bloqué par répertoire.** La protection porte sur `Edit` / `Write`.
