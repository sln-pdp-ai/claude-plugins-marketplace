---
name: structured-logging
description: Conventions de journalisation des microservices PDP - le paquet partagé sln-logger, Logger déprécié contre JsonLogger recommandé, pourquoi un payload interpolé n'est jamais paresseux contrairement au style slf4j, masquage automatique des clés sensibles, consultation des logs via Lumigo. À consulter dès qu'une conversation touche un appel de log, le coût d'un log en chemin chaud, une fuite de donnée sensible dans les logs, ou le choix d'un niveau de log.
---

# Journalisation - `sln-logger`

`sln-logger` est le paquet partagé de journalisation des microservices de l'écosystème. Il expose deux
loggers : `Logger`, **déprécié**, et `JsonLogger`, **recommandé** pour tout nouveau code.

## Le piège central : interpolé n'est pas paresseux

Les deux loggers posent la garde de niveau en **première instruction** de leur méthode de log, avant
toute sérialisation. Un appel en niveau désactivé retourne immédiatement, sans masquer ni formater.

D'où deux comportements opposés selon la forme de l'appel :

| Forme | Paresseux ? | Pourquoi |
|---|---|---|
| `logger.debug('x ' + JSON.stringify(rec))` ou template literal | **non, jamais** | JavaScript évalue l'argument **avant** l'appel. La garde de niveau n'a pas encore tourné. Le `JSON.stringify` d'un gros payload est payé même en production avec `DEBUG` coupé |
| `logger.debug('message', rec)` | **oui** | l'argument structuré n'est touché qu'après la garde. Un niveau désactivé sort avant, coût quasi nul |

C'est le contre-pied du réflexe slf4j (`log.debug("x={}", x)`), où le formatage est délégué au logger et
donc réellement différé. En JavaScript, la seule façon de différer est de **ne pas construire la chaîne**,
donc de passer l'objet en second argument.

Règle pratique en chemin chaud : jamais de payload interpolé dans le message. Le message est une constante
littérale, la donnée passe en second argument.

Si un calcul coûteux doit précéder le log, le garder derrière la méthode de test de niveau exposée par le
logger plutôt que de compter sur une paresse qui n'existe pas.

## Masquage des données sensibles

Les clés dont le nom correspond à `password`, `authorization`, `secret`, `token`, `credentials` sont
masquées automatiquement, par clone profond de la structure.

Deux conséquences à connaître :

- Le masquage n'intervient **qu'après** la garde de niveau, donc il ne coûte rien sur un niveau coupé.
- Il porte sur des **noms de clés**. Une donnée sensible dans une chaîne interpolée, ou sous une clé
  nommée autrement, passe en clair. Le masquage automatique n'est pas une politique de confidentialité, il
  rattrape les cas évidents.

## `JsonLogger` contre `Logger`

`JsonLogger` structure tout appel en un objet à deux champs, le message et la donnée, puis le sérialise en
JSON. Il **ne supporte pas** les substitutions printf (`%o`, `%s`) : elles ressortent littéralement dans
le message au lieu d'être remplacées.

`Logger` est déprécié. Il formate en profondeur illimitée, ce qui produit des lignes très longues sur une
structure profonde. Ne pas l'introduire dans du code neuf.

## Consultation

Les logs et les traces des Lambdas de cet écosystème se consultent via **Lumigo**, pas via la console
CloudWatch. Filtrer par `correlationId` pour suivre un flux de bout en bout, y compris un rejeu S/Bus.

## Ce que ce skill ne sait pas

La version de `sln-logger` épinglée par un service donné, et les points précis du code où un log coûteux
subsiste. Les deux se lisent dans le dépôt concerné.

La **stratégie d'observabilité** du domaine n'est pas ici, volontairement : le catalogue de codes
d'erreur, le RACI de supervision et la cible outillage sont à l'état de proposition, pas de décision. Les
figer dans un plugin publierait une intention pour un fait. Poser la question à l'architecte plutôt que
de citer ce skill.
