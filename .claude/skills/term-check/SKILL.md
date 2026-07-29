---
name: term-check
description: Vérifier que les termes d'une page Confluence, d'une story Jira ou d'un texte sont cohérents avec le glossaire SMT. Signale les termes absents du glossaire ou employés de façon incohérente. Lecture seule.
model: haiku
---

# term-check

Contrôle terminologique contre le glossaire SMT (Confluence). Lecture seule : produit un rapport dans le chat, n'écrit rien.

## Quand l'utiliser
- Avant de raisonner sur une spec ou une story dont le vocabulaire n'est pas sûr.
- Sur demande : `/term-check <URL de page Confluence | clé Jira | texte collé>`.

## Prérequis
- Le glossaire SMT doit exister. S'il n'est pas encore créé (voir CLAUDE.md, section Terminologie), STOP et le signaler : sans glossaire, aucun contrôle fiable n'est possible (fail-fast).

## Étapes
1. Charger la cible : la page Confluence (MCP Atlassian), la story Jira, ou le texte fourni.
2. Charger le glossaire SMT depuis Confluence (espace `SMT`).
3. Extraire les termes métier de la cible (domaines, entités, statuts, acronymes).
4. Pour chaque terme :
   - présent et employé conformément au glossaire : OK ;
   - absent du glossaire : À DÉFINIR ;
   - présent mais employé de façon incohérente : INCOHÉRENT (citer la définition du glossaire).
5. Appliquer le fail-fast : tout terme À DÉFINIR ou INCOHÉRENT sur un point structurant bloque et doit être remonté.

## Format de sortie (dans le chat, en français)
- Tableau : Terme | Statut (OK / À DÉFINIR / INCOHÉRENT) | Source dans la cible | Définition glossaire / écart.
- Conclusion : liste des points bloquants (fail-fast) à lever avant d'aller plus loin.
- Toujours citer les sources (page Confluence, clé Jira, ancre du glossaire). Ne rien inventer.
