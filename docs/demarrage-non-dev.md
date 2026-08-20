# Démarrage pour un profil non-dev

Guide d'installation de l'outillage SMT sur un poste sans VSCode. Environ 20 minutes, une seule fois.
L'outillage n'est plus un projet à récupérer : c'est un **plugin Claude Code** à installer.

Cadrage et justification du choix : [acces-non-dev.md](acces-non-dev.md).

## Prérequis à obtenir avant de commencer

À demander en amont, sinon l'installation s'arrête en cours de route :

| Quoi | Auprès de qui | Pour quoi |
|---|---|---|
| Un siège Claude | Équipe IT / licences | Utiliser Claude Code |
| L'accès au projet GitLab `pdp/ai/claude-plugins-marketplace` | L'architecte | Récupérer le plugin |
| L'accès au dépôt de specs `pdp/smt/sln-smt-spec-owner` | Le PO propriétaire du corpus | Lire les specs et le glossaire |
| Un compte Atlassian Amer Sports | Déjà en place en général | Lire Jira |
| Accès réseau à `gitlab.amersports.com` | VPN si hors site | Récupérer le plugin, puis les specs |

Un **seul compte GitLab** sert pour tout : le plugin et les specs. Les identifiants sont demandés une
fois puis mémorisés.

## Où vivent les specs

Les spécifications et le glossaire sont versionnés en markdown dans
<https://gitlab.amersports.com/pdp/smt/sln-smt-spec-owner> (dossier `solution-overview/`). Le plugin les
récupère lui-même, en lecture seule, dans une copie de travail locale.

Ce qui est publié dans l'espace Confluence `SMT` est une **version synthétique livrée** par le projet
Claude Code du PO. C'est une copie, potentiellement en retard : en cas d'écart, le dépôt git fait foi.

## Installation

### 1. Installer Git for Windows

<https://git-scm.com/download/win>. Accepter les options par défaut. Git sert au plugin pour récupérer
les specs ; vous n'aurez pas à l'utiliser directement, sauf pour la mise à jour décrite plus bas.

### 2. Installer Claude Code

Application desktop Windows. Se connecter avec le compte fourni par l'IT.

### 3. Créer un dossier de travail

Ouvrir PowerShell (menu Démarrer, taper « PowerShell ») et coller :

```powershell
New-Item -ItemType Directory -Force $HOME\Projects\smt-questions
```

Ce dossier n'a pas besoin de contenir quoi que ce soit : c'est simplement l'endroit depuis lequel vous
poserez vos questions. Le plugin y déposera sa copie de travail des specs, dans un sous-dossier
`.smt-tmp`.

### 4. Installer le plugin

Ouvrir ce dossier dans Claude Code, puis taper :

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install smt-spec-quality@pdp-ai
```

Si la réponse demande `/reload-plugins`, le lancer.

Une fenêtre peut demander vos identifiants **GitLab**. Si la réponse est « repository not found »,
c'est que l'accès au projet ne vous a pas encore été donné : GitLab renvoie ce message aussi bien pour
un dépôt inexistant que pour un dépôt sans droits.

Les profils techniques installent en plus `smt-code-crosscheck@pdp-ai`, qui compare les specs au code.
Sans accès aux dépôts de code, il ne sert à rien.

### 5. Connecter Jira

```
/mcp
```

Choisir le serveur `atlassian` du plugin, puis s'authentifier dans le navigateur avec le compte
Atlassian Amer Sports. Les jetons restent sur votre poste.

Cette étape ne sert qu'à désigner une story par sa clé (`SMT-123`). Les specs, elles, sont lues dans la
copie de travail : elles restent accessibles même si l'authentification Atlassian échoue.

### 6. Vérifier

```
/smt-spec-quality:term-check Size Grid Code
```

Au premier lancement, le plugin annonce qu'il récupère les specs, puis répond en citant
`solution-overview/glossary.md` avec un numéro de ligne. S'il répond sans aucune source, quelque chose
n'est pas branché.

## Usage courant

Les commandes du plugin `smt-spec-quality` :

| Commande | Ce qu'elle fait |
|---|---|
| `/smt-spec-quality:term-check <fichier de spec, story ou texte>` | Vérifie la cohérence des termes avec le glossaire |
| `/smt-spec-quality:spec-readiness <fichier de spec, epic ou story>` | Dit si une spec est prête pour le dev |

Le préfixe `smt-spec-quality:` est imposé par Claude Code pour les commandes venant d'un plugin. Vous
pouvez aussi poser vos questions en langage naturel. Pour désigner une spec, le plus simple est son
chemin dans le corpus, par exemple
`solution-overview/functional-specifications/1-generic-properties.md`.

### Garder les specs à jour

La copie de travail est figée au moment où le plugin l'a récupérée. Une copie périmée fait répondre
faux, sans aucun signal. Le plugin contrôle donc la fraîcheur avant chaque réponse, et **refuse de
conclure** sur une copie en retard, y compris pour une simple question de vocabulaire.

Il ne met pas à jour de lui-même, par principe : il est en lecture seule. Quand il signale un retard :

```powershell
git -C $HOME\Projects\smt-questions\.smt-tmp\sln-smt-spec-owner pull --ff-only
```

Le chemin exact figure dans le message du plugin. Pour mettre à jour le plugin lui-même, quand
l'architecte annonce une nouvelle version : `/plugin update smt-spec-quality`.

## Ce que l'outillage ne fait pas

Il ne crée ni ne modifie aucune issue Jira, aucune page Confluence, aucun fichier de spec et aucun
fichier de code : ce n'est pas une préférence, les outils d'écriture correspondants sont bloqués par le
plugin. Ses sorties sont des propositions, à appliquer par un humain ; une correction de spec est à
porter par le PO dans son propre projet.

Il s'arrête aussi volontairement quand une spec est floue, ambiguë ou contradictoire, au lieu de
deviner. Une réponse « je ne peux pas conclure, voici ce qui manque » est un résultat, pas une panne.

## En cas de problème

| Symptôme | Cause probable | Quoi faire |
|---|---|---|
| `git est introuvable` | Étape 1 sautée, ou fenêtre ouverte avant l'installation | Installer git, rouvrir PowerShell |
| Le marketplace refuse de s'ajouter | Accès à `pdp/ai/claude-plugins-marketplace` non accordé, ou VPN absent | Le demander à l'architecte, vérifier le VPN |
| Les commandes `/smt-spec-quality:...` n'apparaissent pas | Plugin installé mais non rechargé | `/reload-plugins`, puis `/plugin list` pour vérifier |
| Le plugin ne trouve pas les specs | Accès au dépôt de specs non accordé | Le demander au PO ; sans lui, ni specs ni glossaire |
| `fetch impossible` | VPN coupé, ou droits GitLab manquants | Vérifier le VPN, puis les droits |
| Le plugin annonce un retard et s'arrête | Comportement normal | Lancer le `git pull` ci-dessus, puis relancer la commande |
| Il ne voit pas Jira | Étape 5 non faite ou OAuth expiré | Refaire `/mcp` sur `atlassian` |
| Réponses sans `fichier:ligne` | Copie de travail absente | Relancer la commande ; le plugin doit annoncer la récupération |
| Il cite Confluence pour une règle | Réflexe de l'ancien câblage | Lui demander la source dans le corpus git ; Confluence n'est plus la référence |
