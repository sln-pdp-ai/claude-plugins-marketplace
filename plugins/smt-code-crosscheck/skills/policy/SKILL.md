---
name: policy
description: Doctrine SMT et localisation du corpus de specs. À lire avant toute réponse portant sur une spécification, un terme métier, une règle de gestion ou une story SMT, et avant d'invoquer un autre skill SMT. Contient l'ordre de résolution des dépôts, le contrôle de fraîcheur obligatoire et les règles de citation.
---

# Doctrine SMT

Ce skill **est** la référence de la doctrine SMT : elle ne vit nulle part ailleurs. Un plugin ne peut
pas livrer de `CLAUDE.md` : un fichier de ce nom à la racine d'un plugin n'est pas chargé comme
contexte de projet. Le noyau est donc injecté au démarrage par un hook, et le détail est ici.

## Priorité absolue : fail-fast

Cette règle prime sur toute autre tâche.

- Dès qu'une spécification est floue, ambiguë, imprécise, incomplète ou contradictoire (en interne, ou
  vis-à-vis de Jira, du code, du glossaire), STOP immédiat.
- Ne pas deviner, ne pas masquer le manque, ne pas continuer sur une hypothèse.
- Signaler précisément : ce qui est flou, où (`fichier:ligne`, identifiant EARS, clé d'issue), pourquoi
  cela bloque, et ce qu'il faut pour lever le doute.
- Une question ouverte du corpus (`SMT-<MODULE>-OQ-<NN>`) qui porte sur le sujet traité est un
  bloquant, pas une nuance à contourner. Idem pour tout « TBC », « à confirmer », « to be discussed ».
- Terminer en silence est un échec : « fait » est faux si quoi que ce soit a été sauté ou supposé.

## Sources de vérité

| Source | Statut | Usage |
|---|---|---|
| Corpus de specs `sln-smt-spec-owner` (markdown versionné) | source de vérité | specs fonctionnelles, glossaire, référentiel |
| Jira, projet `SMT` | source de vérité pour le découpage | epics, stories, statuts, sprints |
| Code `sln-smt-backend`, `sln-smt-console` | source de vérité pour ce qui est développé | via checkout local |
| Confluence, espace `SMT` | **dérivé** | livraison synthétique produite par le projet du spec owner : copie datée, possiblement en retard |

En cas d'écart entre le git et Confluence, **le git fait foi**, et l'écart se signale comme une dérive
de la livraison. Ne citer Confluence que pour ce que le markdown ne porte pas : les diagrammes draw.io
de `process-overview` et `overall-architecture`, non exportés.

## Terminologie : le glossaire fait autorité

- Le glossaire est `solution-overview/glossary.md` dans le corpus de specs.
- Il porte, par terme : nom métier, nom technique, références EARS qui le définissent normativement
  (colonne « Spec ref »), statut de validation, et écart de vocabulaire éventuel avec le PMD.
- Citer la référence EARS plutôt que le seul libellé. Ne jamais inventer de définition ; reprendre la
  formulation exacte.
- Un statut 🔴 Not validated ou ⚪ To discuss n'est pas une validation : le signaler quand le terme est
  structurant pour la question posée.
- Terme absent du glossaire, ou employé de façon incohérente avec lui : incohérence fail-fast.

## Conventions du corpus

- Exigences EARS `SMT-<MODULE>-<NNN>`, numérotation locale au module (GP, CT, DT, CL, RD, OA, AL, DB,
  RF). Un identifiant n'est jamais réutilisé.
- Questions ouvertes `SMT-<MODULE>-OQ-<NN>`, centralisées dans
  `functional-specifications/overall-questions.md` et rappelées par module.
- Slices verticales `SMT-VS-<NN>` et enablers `SMT-EN-<NN>` : ils référencent les exigences sans jamais
  recopier leur texte. Pour la règle elle-même, remonter à l'exigence.
- `functional-specifications/post-mvp-out-of-golive-scope.md` liste ce qui est volontairement hors MVP.
- Deux familles de règles à toujours distinguer : **Integrity** (toujours vraie, jamais levée, même par
  un Override) et **Lifecycle** (dépend du statut, levable par un Override Admin).
- `vertical-slices/index.md` fait la liste des slices, jamais le contenu du dossier : une slice sans
  page détaillée n'est pas une slice inexistante.

## Où est le corpus, et est-il exploitable

Ne jamais supposer un chemin. Le plugin résout les dépôts, dans cet ordre :

1. la variable d'environnement dédiée (`SMT_SPEC_DIR`, `SMT_BACKEND_DIR`, `SMT_CONSOLE_DIR`) ;
2. le projet courant, s'il **est** le dépôt cherché ;
3. `repos/<nom>` sous le projet courant ;
4. un dépôt frère `../<nom>` ;
5. un clone de travail dans le dossier `.smt-tmp/` du projet courant, ou dans le cache utilisateur si
   git n'ignore pas ce dossier.

Avant toute lecture de spec, y compris une simple question de vocabulaire, et avant toute comparaison
spec / code :

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/smt-repos.ps1" -Action check -Need <spec|code|all>
```

Chaque skill donne la valeur de `-Need` qui lui correspond : ne demander que les dépôts dont la réponse
dépend. `-Action paths` répond sans accès réseau quand seule la localisation est en jeu.

Interprétation, en fail-fast :

- `A_JOUR` : continuer.
- `EN_RETARD` : STOP. Donner le nombre de commits et la date du dernier commit distant, demander un
  rafraîchissement. Ne jamais rafraîchir soi-même : `git pull` modifie le checkout. Ne poursuivre que
  si l'utilisateur l'accepte explicitement, et le rappeler dans la sortie.
- `FETCH_KO` : STOP. La fraîcheur est invérifiable, donc toute conclusion l'est aussi.
- `SALE` : le working tree du dépôt lu n'est pas vide, ce qui est lu ne correspond plus à ce qui est
  versionné. Le signaler avant de continuer.
- `ABSENT` : STOP. Annoncer ce qui va être cloné et où, puis, seulement après accord,
  `-Action ensure`. Un clone de travail est une copie de lecture : ne jamais y écrire, ne jamais y
  commiter.

## Périmètre d'écriture

- Aucune écriture Jira, aucune écriture Confluence. Bloqué techniquement par un hook `PreToolUse`.
- Aucune modification du corpus de specs ni du code lus en source, aucun commit. Bloqué par le même
  hook pour les dépôts que le plugin résout comme sources externes.
- Exception assumée : le dépôt que l'utilisateur a ouvert comme projet courant n'est pas protégé par le
  plugin. Le spec owner rédige ses specs chez lui, un dev écrit son code chez lui. Ce n'est pas une
  autorisation d'écrire à sa place : les sorties de ces skills restent des propositions, portées par la
  personne propriétaire.
- Aucune affirmation sans source : `fichier:ligne`, identifiant EARS, ou clé Jira.
