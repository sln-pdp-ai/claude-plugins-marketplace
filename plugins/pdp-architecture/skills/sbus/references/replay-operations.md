# Déclencher et suivre un rejeu

Côté exploitation. Ce que fait un opérateur, un PO ou un dev qui veut provoquer un rejeu et vérifier
qu'il s'est déroulé.

## Déclencher un rejeu à la main

Depuis la **console de support Salomon Bus**, outil interne :

1. Aller sur la publication de message.
2. Choisir le topic de requête, c'est-à-dire le topic standard visé suffixé de `-request`. Son nom exact
   se lit dans le code du producteur ou dans la liste des topics de la console, pas de mémoire.
3. Composer le payload `content` avec les critères de filtre, par exemple `{ "locale": "fr-FR" }`.
4. Générer un `correlationId` neuf, un UUIDv4, et le poser dans `context`.
5. Optionnellement poser le `onlyTo` d'enveloppe sur le nom du producteur visé, quand plusieurs
   producteurs partagent l'espace de noms du topic.
6. Optionnellement poser `content.onlyTo` pour rediriger la réponse ailleurs que sur l'application
   émettrice de la demande.
7. Publier.
8. Surveiller le topic standard, ou les journaux de l'application aval, en cherchant le `correlationId`.

Le `correlationId` est la seule prise pour retrouver un rejeu ensuite. Le générer avant de publier et le
garder de côté.

## Suivre un rejeu

| Moyen | Ce qu'on y voit |
|---|---|
| Lumigo, filtrer par `correlationId` | la trace complète du rejeu : demande reçue, interrogation de la persistance, messages republiés |
| Journaux de la Lambda du producteur | les entrées portant le `correlationId`, dont le nombre d'enregistrements correspondants |
| Tableau de bord de supervision du Salomon Bus | les compteurs de publication et de consommation par topic. Un pic sur le topic standard après un message sur le topic `-request` signale un rejeu en cours |

Les journaux et les traces des Lambdas se consultent via **Lumigo**, pas via la console CloudWatch.

## Tâches d'exploitation courantes

| Tâche | Comment |
|---|---|
| Amorcer un nouveau consommateur | publier une demande avec un filtre large, `{}` pour tout rejouer |
| Rejouer un seul article | `{ "articleCode": "L41681700" }` |
| Rejouer une plage de dates | `{ "updatedAt": { "$gte": "2026-03-01", "$lt": "2026-04-01" } }` |
| Estimer un rejeu avant de le lancer | `{ "dryRun": true }`, si le producteur le supporte |
| Tester un consommateur sans toucher à l'amont | déclencher un rejeu sur un filtre étroit |
| Rediriger un rejeu vers un autre consommateur | `content.onlyTo` sur le nom de l'application cible |
| Diffuser un rejeu à tous les abonnés | `content.onlyTo` à `null` |

## Interrompre un rejeu

**Pas possible.** Un rejeu lancé va jusqu'au bout. Il n'existe pas de mécanisme d'annulation.

Le seul contournement est côté aval : ignorer les messages portant le `correlationId` devenu indésirable.
D'où l'intérêt de générer un `correlationId` distinct par rejeu, et de passer par `dryRun` avant un rejeu
large.

## Ce qui peut mal se passer

| Symptôme | Piste |
|---|---|
| Aucun message ne revient | le `onlyTo` d'enveloppe de la demande ne correspond à aucun producteur, ou une clé de filtre obligatoire manquait et la demande a été rejetée |
| Les messages arrivent chez un autre consommateur | `content.onlyTo` a été posé, ou le `context.application` de la demande n'était pas celui attendu, cas fréquent quand la demande part de la console de support |
| Tous les abonnés du topic reçoivent le rejeu | `content.onlyTo` était présent à `null`, donc opt-out du ciblage |
| Le rejeu recommence en boucle | le producteur lève une erreur là où il devrait terminer silencieusement, le message repasse en file |
| L'aval ne reconnaît pas ses messages | le `correlationId` n'est pas propagé par le producteur, ou l'aval compare l'`uuid` au lieu du `correlationId` |
