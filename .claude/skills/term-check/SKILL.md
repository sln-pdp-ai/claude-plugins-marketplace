---
name: term-check
description: Vérifier que les termes d'un fichier de spec, d'une story Jira ou d'un texte sont cohérents avec le glossaire SMT (repos/sln-smt-spec-owner/solution-overview/glossary.md). Signale les termes absents du glossaire ou employés de façon incohérente. Lecture seule.
model: haiku
---

# term-check

Contrôle terminologique contre le glossaire SMT, versionné dans le dépôt de specs. Lecture seule :
produit un rapport dans le chat, n'écrit rien.

## Quand l'utiliser
- Avant de raisonner sur une spec ou une story dont le vocabulaire n'est pas sûr.
- Sur demande : `/term-check <chemin d'un fichier de spec | clé Jira | terme | texte collé>`.

## Prérequis
- Le glossaire est `repos/sln-smt-spec-owner/solution-overview/glossary.md`. S'il est absent (dépôt de
  specs non cloné), STOP : sans glossaire, aucun contrôle fiable n'est possible (fail-fast). Indiquer
  `.\scripts\bootstrap.ps1` comme correctif.
- **Clone à jour** : appliquer le contrôle de fraîcheur de CLAUDE.md (« Fraîcheur des clones ») sur
  `sln-smt-spec-owner` avant l'étape 2. Un glossaire périmé valide des termes qui ont changé de
  définition. En retard, `fetch` impossible ou working tree non vide : s'arrêter et le signaler.
- Ne jamais utiliser la copie Confluence du glossaire quand le fichier git est disponible : c'est une
  livraison dérivée, possiblement en retard.

## Étapes
1. Charger la cible : le fichier de spec (Read), la story Jira (MCP Atlassian), ou le texte fourni.
2. Charger le glossaire depuis `repos/sln-smt-spec-owner/solution-overview/glossary.md`.
3. Extraire les termes métier de la cible (entités, statuts, propriétés, acronymes).
4. Pour chaque terme :
   - présent et employé conformément au glossaire : OK ;
   - absent du glossaire : À DÉFINIR ;
   - présent mais employé de façon incohérente : INCOHÉRENT (citer la définition du glossaire) ;
   - présent mais au statut 🔴 Not validated ou ⚪ To discuss : NON VALIDÉ, à signaler quand le terme
     est structurant pour la question posée.
5. Vérifier la colonne « Gap (PMD / Colin) » : si la cible emploie le terme PMD au lieu du terme SMT,
   le signaler comme écart de vocabulaire, pas comme erreur.
6. Appliquer le fail-fast : tout terme À DÉFINIR ou INCOHÉRENT sur un point structurant bloque et doit
   être remonté.

## Format de sortie (dans le chat, en français)
- Tableau : Terme | Statut (OK / À DÉFINIR / INCOHÉRENT / NON VALIDÉ) | Source dans la cible | Définition glossaire (avec réf. EARS) / écart.
- Conclusion : liste des points bloquants (fail-fast) à lever avant d'aller plus loin.
- Toujours citer les sources : `fichier:ligne` pour la spec et le glossaire, clé Jira pour une story.
  Ne rien inventer.
