# Démarrage pour un profil non-dev

Guide d'installation de l'assistant SMT sur un poste sans VSCode. Environ 30 minutes, une seule
fois. Aucune connaissance de git n'est requise : un script fait le travail.

Cadrage et justification du choix : [acces-non-dev.md](acces-non-dev.md).

## Prérequis à obtenir avant de commencer

À demander en amont, sinon l'installation s'arrête en cours de route :

| Quoi | Auprès de qui | Pour quoi |
|---|---|---|
| Un siège Claude | Équipe IT / licences | Utiliser Claude Code |
| L'accès au projet GitLab de l'assistant (`pdp/ai`) | L'architecte | Récupérer l'assistant |
| Un compte GitLab avec accès aux deux dépôts SMT | Owner des dépôts | Lire le code |
| Un compte Atlassian Amer Sports | Déjà en place en général | Lire Confluence et Jira |
| Accès réseau à `gitlab.amersports.com` | VPN si hors site | Cloner et rafraîchir le code |

## Où vit l'assistant

Le projet est publié sur `gitlab.amersports.com`, dans le groupe **`pdp/ai`** :
<https://gitlab.amersports.com/pdp/ai/sln-smt-assistant>, branche `main`.

Deux conséquences pratiques :

- L'accès au projet doit vous être donné avant de commencer. Le demander en même temps que les autres
  prérequis, sinon l'étape 3 échoue sur un « repository not found ».
- Un **seul compte** suffit : le même GitLab sert pour l'assistant (étape 3) et pour le code SMT
  (étape 4). Les identifiants sont demandés une fois puis mémorisés. Il faut en revanche l'accès
  réseau à `gitlab.amersports.com` (VPN si hors site) dès l'étape 3.

## Installation

### 1. Installer Git for Windows

<https://git-scm.com/download/win>. Accepter les options par défaut. Git sert uniquement à récupérer
le code ; vous n'aurez pas à l'utiliser directement.

### 2. Installer Claude Code

Application desktop Windows. Se connecter avec le compte fourni par l'IT.

### 3. Récupérer le projet de l'assistant

Ouvrir PowerShell (menu Démarrer, taper « PowerShell ») et coller :

```powershell
cd $HOME\Projects        # ou le dossier de votre choix ; le creer s'il n'existe pas
git clone https://gitlab.amersports.com/pdp/ai/sln-smt-assistant.git
cd sln-smt-assistant
```

Une fenêtre demande vos identifiants **GitLab**. Ils sont ensuite mémorisés. Si la réponse est
« repository not found », c'est que l'accès au projet ne vous a pas encore été donné : le
message est le même que pour un dépôt inexistant.

### 4. Lancer le bootstrap

```powershell
.\scripts\bootstrap.ps1
```

Le script vérifie git, clone les deux dépôts SMT dans `repos/`, et contrôle qu'ils sont à jour et
intacts. Il ne modifie jamais rien sur GitLab. Vos identifiants **GitLab** ont déjà été mémorisés à
l'étape 3 ; ils resservent tels quels pour les deux dépôts SMT.

Si PowerShell refuse d'exécuter le script (politique d'exécution), lancer une seule fois :

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Le script se termine par un bilan. Tout doit être en `OK` avant de continuer.

### 5. Connecter Confluence et Jira

Ouvrir le dossier `sln-smt-assistant` dans Claude Code, puis :

1. Approuver le serveur MCP du projet quand il est proposé.
2. Taper `/mcp`, choisir `atlassian`, s'authentifier dans le navigateur avec le compte Atlassian
   Amer Sports.

### 6. Vérifier

Taper `/spec-readiness SMT`. L'assistant doit répondre en citant des pages Confluence ou des issues
Jira. S'il répond sans aucune source, quelque chose n'est pas branché.

## Usage courant

Les commandes disponibles :

| Commande | Ce qu'elle fait |
|---|---|
| `/term-check <page, story ou texte>` | Vérifie la cohérence des termes avec le glossaire |
| `/spec-readiness <epic, story ou page>` | Dit si une spec est prête pour le dev |
| `/spec-vs-code <clé ou page>` | Compare la spec au code réellement écrit |
| `/doc-freshness <page>` | Liste ce qui est périmé dans une page Confluence |
| `/refactor-proposal <zone>` | Propose des refactorings, sans les appliquer |
| `/explore-code <question>` | Explore le code et rend une synthèse sourcée |

Vous pouvez aussi poser vos questions en langage naturel.

### Rafraîchir avant toute question sur le code

Le code de `repos/` est une copie locale, figée au moment du clone. Une copie périmée fait répondre
faux, sans aucun signal d'alerte. Avant une session portant sur le code :

```powershell
.\scripts\bootstrap.ps1 -Update
```

Les commandes `/spec-vs-code`, `/doc-freshness` et `/refactor-proposal` contrôlent la fraîcheur
d'elles-mêmes et refusent de conclure sur une copie périmée. Le script reste le moyen le plus simple
de remettre tout à niveau d'un coup.

## Ce que l'assistant ne fait pas

Il est en **lecture seule** sur les trois sources : il ne crée ni ne modifie aucune page Confluence,
aucune issue Jira, aucun fichier de code. Ses sorties sont des propositions, à appliquer par un
humain. Ce n'est pas une préférence : les outils d'écriture sont bloqués dans la configuration du
projet.

Il s'arrête aussi volontairement quand une spec est floue, ambiguë ou contradictoire, au lieu de
deviner. Une réponse « je ne peux pas conclure, voici ce qui manque » est un résultat, pas une panne.

## En cas de problème

| Symptôme | Cause probable | Quoi faire |
|---|---|---|
| `git est introuvable` | Étape 1 sautée, ou fenêtre ouverte avant l'installation | Installer git, rouvrir PowerShell |
| `repository not found` à l'étape 3 | Accès au projet GitLab `pdp/ai/sln-smt-assistant` non accordé (ou VPN absent) | Le demander à l'architecte ; GitLab renvoie ce message aussi bien pour un dépôt inexistant que pour un dépôt sans droits |
| `Clone echoue` / `fetch impossible` | VPN coupé, ou droits GitLab manquants | Vérifier le VPN, puis les droits sur les deux dépôts |
| `Working tree non vide` | Un fichier de `repos/` a été modifié en local | Ne rien éditer sous `repos/` ; demander de l'aide pour remettre à plat |
| L'assistant ne voit ni Confluence ni Jira | Étape 5 non faite ou OAuth expiré | Refaire `/mcp` sur `atlassian` |
| Réponses sans `fichier:ligne` sur le code | `repos/` vide | Relancer `.\scripts\bootstrap.ps1` |
