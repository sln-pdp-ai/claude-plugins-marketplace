---
name: term-check
description: Vérifier que les termes d'un fichier de spec, d'une story Jira ou d'un texte sont cohérents avec le glossaire SMT. Signale les termes absents du glossaire, employés de façon incohérente, ou non validés. Lecture seule.
model: haiku
---

# term-check

Contrôle terminologique contre le glossaire SMT, versionné dans le corpus de specs. Lecture seule :
produit un rapport dans le chat, n'écrit rien.

## Quand l'utiliser
- Avant de raisonner sur une spec ou une story dont le vocabulaire n'est pas sûr.
- Sur demande : `/smt-spec-quality:term-check <fichier de spec | clé Jira | terme | texte collé>`.

## Prérequis
1. Lire le skill `policy` de ce plugin : doctrine, conventions du corpus, résolution des dépôts.
2. Localiser et valider le corpus :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need spec
```

   Verdict autre que `A_JOUR` : s'arrêter et appliquer l'interprétation fail-fast du skill `policy`. Un
   glossaire périmé valide des termes qui ont changé de définition, sans aucun signal.
3. Ne jamais utiliser la copie Confluence du glossaire : c'est une livraison dérivée.

## Étapes
1. Charger la cible : le fichier de spec (Read), la story Jira (MCP Atlassian), ou le texte fourni.
2. Charger `solution-overview/glossary.md` depuis le chemin résolu à l'étape 2 des prérequis.
3. Extraire les termes métier de la cible (entités, statuts, propriétés, acronymes).
4. Pour chaque terme :
   - présent et employé conformément au glossaire : OK ;
   - absent du glossaire : À DÉFINIR ;
   - présent mais employé de façon incohérente : INCOHÉRENT (citer la définition du glossaire) ;
   - présent mais au statut 🔴 Not validated ou ⚪ To discuss : NON VALIDÉ, à signaler quand le terme
     est structurant pour la question posée.
5. Vérifier la colonne « Gap (PMD / Colin) » : si la cible emploie le terme PMD au lieu du terme SMT,
   le signaler comme écart de vocabulaire, pas comme erreur.
6. Fail-fast : tout terme À DÉFINIR ou INCOHÉRENT sur un point structurant bloque et doit être remonté.

## Format de sortie (français, dans le chat)
- Tableau : Terme | Statut (OK / À DÉFINIR / INCOHÉRENT / NON VALIDÉ) | Source dans la cible | Définition glossaire (avec réf. EARS) / écart.
- Conclusion : liste des points bloquants (fail-fast) à lever avant d'aller plus loin.
- Toujours citer les sources : `fichier:ligne` pour la spec et le glossaire, clé Jira pour une story.
