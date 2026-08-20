---
name: sbus
description: Sémantique du S/Bus (Salomon Bus) dans l'écosystème produit PDP - convention de nommage des topics, structure de l'enveloppe de message, pattern replay via topic -request, propagation du correlationId, ciblage par onlyTo. À consulter dès qu'une conversation touche un topic S/Bus, une publication ou une consommation de message, un rejeu de données, ou la rédaction d'une story sur un flux inter-applicatif.
---

# S/Bus - sémantique et pattern replay

Le S/Bus (Salomon Bus) est le bus de messages publish / subscribe de l'écosystème produit
Salomon / Amer Sports. Payloads JSON, contrats en JSON Schema, un topic par flux métier.

Ne jamais écrire « enterprise bus ». Les seules formes admises sont **S/Bus** et **Salomon Bus**.

## Ce que ce skill sait, et ce qu'il ne sait pas

Ce skill porte le savoir **stable** : conventions, invariants, sémantique des champs. Il reste vrai d'une
année sur l'autre.

Il ne contient **aucun** chemin de fichier, nom de handler, constante, version de package ni SHA. Ces
éléments changent à chaque sprint et une affirmation figée ici serait fausse en silence. Si la question
posée en exige un, il faut lire le code du service concerné, jamais le déduire de ce skill.

Formulation correcte : « le producteur souscrit au topic `-request` et republie sur le topic standard ».
Formulation interdite : « le handler `recordRequestSqs.ts` pagine par 10 ». La seconde peut être vraie
aujourd'hui, elle n'est pas vérifiable d'ici.

### Les noms de topics sont périssables, eux aussi

**Aucun nom de topic cité dans ce skill ou ses références ne doit être repris comme le nom courant.** Les
topics sont renommés au fil des sprints, et la liste des topics auxquels un service souscrit change dès
qu'on lui ajoute une souscription. Un même flux a déjà porté trois orthographes différentes dans la
documentation interne.

Ce qui est stable, c'est la **forme** du nom et le rôle du suffixe `-request`. Les noms complets qui
apparaissent ci-dessous sont des illustrations de cette forme, pas un annuaire.

Pour connaître le nom réel d'un topic, ou la liste réelle des souscriptions d'un service, lire le code du
service. Une story qui cite un topic doit tenir ce nom d'une vérification dans le dépôt, jamais de ce
skill.

## Convention de nommage des topics

| Rôle | Forme, qui est le fait stable | Illustration de la forme |
|---|---|---|
| Topic standard, porte les événements | `<domaine>-<entité>-<canal>` | `pim-product-catalog-<canal>` |
| Topic de requête, porte les demandes de rejeu | `<domaine>-<entité>-<canal>-request` | `pim-product-catalog-<canal>-request` |

Tout topic standard peut avoir son jumeau `-request`. Le suffixe est le seul marqueur : il n'existe pas
de topic de réponse dédié, le rejeu ressort sur le topic standard.

La colonne de droite illustre la forme. Elle ne dit pas quels canaux existent réellement aujourd'hui, ni
sous quelle orthographe.

## Le pattern replay en une phrase

Un consommateur aval publie une demande filtrée sur le topic `-request` ; le producteur amont la reçoit,
interroge sa propre persistance, et republie les enregistrements correspondants sur le topic standard, en
marquant chaque message du `correlationId` de la demande.

Le rejeu sert à amorcer un nouveau consommateur sur un topic déjà actif, à reconstruire un cache ou une
base aval après migration, à se remettre d'un échec de traitement sans repasser par le système source, et
à tester un flux avec un volume réaliste.

## Les sept invariants d'un rejeu

Tout producteur qui implémente le pattern respecte ces sept règles. Elles constituent l'ossature d'une
story de rejeu, une règle par point.

1. **Souscription** au topic `<topic standard>-request`.
2. **Périmètre canonique** : le producteur applique d'abord ses critères métier fixes, ceux dont il est
   autoritaire. Non négociables, appliqués quelle que soit la demande.
3. **Filtres de la demande** appliqués **par dessus** le périmètre canonique. Le producteur déclare
   quelles clés sont autorisées, lesquelles sont obligatoires, lesquelles acceptent plusieurs valeurs.
   Une clé obligatoire absente fait rejeter la demande sans interroger la persistance.
4. **Republication à l'identique** sur le topic standard : même JSON Schema, même forme de payload que le
   flux d'événements normal. Un consommateur ne doit pas avoir à distinguer les deux.
5. **Complétion silencieuse** quand rien ne correspond : zéro message publié, aucune erreur levée.
6. **Propagation du `correlationId`** : celui de la demande est recopié dans le `context` de chaque
   message republié. C'est le seul moyen pour l'aval de reconnaître son rejeu.
7. **Résolution du `onlyTo`** : `content.onlyTo` de la demande s'il est présent, sinon
   `context.application` de la demande. `content.onlyTo` à `null` est un opt-out explicite qui diffuse à
   tous les abonnés du topic standard.

La règle 7 mérite son attention : le défaut garde le flux de rejeu privé au demandeur, ce qui évite
d'inonder les autres abonnés de données qu'ils n'ont pas demandées. L'override existe pour les rejeux
déclenchés depuis la console par un opérateur au nom d'une autre application, et pour les backfills
larges.

## Enveloppe de message, l'essentiel

```
context.env                environnement (QUAL, PROD, ...)
context.application        application émettrice
context.uuid               identifiant unique de CE message
context.postedDate         horodatage de publication
context.correlationId      identifiant de corrélation, clé du rejeu
context.systemOrigin       système à l'origine de la demande
topic                      nom du topic
entityNaturalId            identifiant métier de l'entité
entityUpdatedDate          dernière mise à jour dans le système source
onlyTo                     ciblage de la livraison
params                     paramètres libres
content                    payload métier, ou critères de filtre sur un topic -request
```

Trois pièges récurrents sur cette enveloppe :

- `onlyTo` au niveau enveloppe d'une **demande** restreint quel producteur doit la traiter. Il ne
  détermine pas la cible de la réponse.
- `content.onlyTo` au niveau payload d'une **demande** détermine, lui, la cible des messages republiés.
  Deux champs de même nom, deux rôles opposés.
- `context.uuid` d'un message republié est **neuf**. Ce n'est pas l'UUID de l'événement d'origine. Seuls
  `correlationId` et `entityUpdatedDate` se propagent.

## Style d'intégration

Interconnexion de SaaS par microservices AWS construits avec Serverless Framework v3. Le flux le plus
courant de l'écosystème :

```
export de channel Salsify -> webhook sur le microservice -> lecture du JSON depuis S3
-> transformation -> persistance -> publication sur un topic S/Bus
```

Les souscriptions S/Bus ne sont pas déclarées en événements `sqs:` bruts : elles passent par le plugin
Serverless interne, qui lit les topics souscrits dans le code des handlers et provisionne les files et
les DLQ. Conséquence pratique quand on lit un service : la liste des topics consommés ne se trouve pas
dans le manifeste Serverless, mais dans le code.

## Où aller ensuite

| Question | Référence |
|---|---|
| Un champ précis de l'enveloppe, un exemple complet de demande et de réponse | [references/message-envelope.md](references/message-envelope.md) |
| Implémenter le rejeu dans un producteur : souscription, pagination, gestion d'erreur, `dryRun` | [references/replay-implementation.md](references/replay-implementation.md) |
| Déclencher et suivre un rejeu, tâches d'exploitation courantes | [references/replay-operations.md](references/replay-operations.md) |

La **rédaction** de la story de rejeu n'est pas ici : le format des règles et des critères d'acceptation
appartient au plugin `pdp-po-workbench`. Ce skill fournit la matière métier, pas la mise en forme du
livrable.

## Questions encore ouvertes sur le pattern

Deux points ne sont pas tranchés à l'échelle de l'écosystème. Les signaler comme tels plutôt que de
choisir à la place de l'architecte.

- Le schéma de demande doit-il porter un filtre temporel `sinceDate` / `untilDate` ?
- Le producteur doit-il émettre un message de fin de rejeu sur un topic `-response` dédié ?
