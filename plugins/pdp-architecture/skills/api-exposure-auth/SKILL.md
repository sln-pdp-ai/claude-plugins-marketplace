---
name: api-exposure-auth
description: Exposition d'API et authentification dans les microservices PDP - l'APIM interne de l'équipe Platform en amont, AWS API Gateway et authorizer Auth0 dans le service, allowlist IP pour les webhooks SaaS auto-signés, validation de schéma avant invocation, contrat OpenAPI, jetons machine à machine, API plateforme centralisées. À consulter dès qu'une conversation touche un endpoint HTTP, un webhook entrant, l'authentification d'un appel, un appel de service à service, un contrat d'API, ou un 401 / 403 inexpliqué.
---

# Exposition d'API et authentification

## Deux étages : l'APIM Platform en amont, API Gateway dans le service

Il existe un **API management interne, opéré par l'équipe Platform**. Il est en amont des microservices.

Point important pour ne pas conclure de travers : **cet APIM ne laisse aucune trace dans le code des
microservices** - ni manifeste, ni dépendance, ni configuration. Chercher dans un dépôt de service ne
donne rien, et cette absence ne veut pas dire qu'il n'y a pas d'APIM. Toute question sur l'APIM lui-même,
son routage, ses politiques d'exposition ou ses quotas, se pose à l'équipe Platform et ne se déduit pas du
code.

Ce que le service porte lui-même, et qui est visible dans son dépôt, tient en quatre mécanismes :
l'authorizer Lambda, la resource policy d'API Gateway, la validation de schéma par API Gateway, et le
contrat OpenAPI. C'est de ces quatre-là que parle la suite.

## Authentification des appels entrants

Chaque service protège ses endpoints HTTP par un **authorizer Lambda** qui valide un JWT **Auth0** contre
une liste d'IDP configurés. Les IDP rencontrés sont `salomon`, `azure` et `auth0`, la liste étant déclarée
par service.

Deux implémentations coexistent, et savoir laquelle on regarde évite de chercher au mauvais endroit :

- le bloc partagé, configuré dans le manifeste Serverless avec sa liste d'IDP, sa durée de mise en cache
  du résultat et sa liste d'endpoints exclus ;
- un authorizer réécrit à la main dans le service, quand le besoin sortait du cadre du bloc partagé.

## Les webhooks SaaS : allowlist IP, jamais l'authorizer

Un endpoint appelé par un SaaS ou un bus externe qui **se signe lui-même** (notification d'un DAM, callback
de bus) est explicitement **exclu de l'authorizer** et protégé uniquement par une **resource policy API
Gateway en allowlist d'adresses IP**.

Les deux mécanismes ne sont **jamais combinés sur le même endpoint**. C'est un choix, pas un oubli :
l'appelant externe ne peut pas produire de JWT Auth0, donc lui imposer l'authorizer le bloquerait.

Conséquence pratique quand un webhook tombe en 403 : regarder l'allowlist IP avant de suspecter Auth0.
L'inverse pour un endpoint métier.

## Validation de schéma avant le code

Chaque endpoint, métier ou callback de bus, déclare un **schéma JSON** validé **par API Gateway lui-même**
avant l'invocation de la Lambda. Un corps de requête invalide reçoit un `400` **sans qu'aucune ligne de
code métier ne s'exécute**.

À retenir pour une story ou un débogage : la validation de forme n'est pas dans le handler. Écrire une
règle de validation de forme dans le code métier duplique ce que la passerelle fait déjà, et le handler ne
verra jamais le cas.

## Contrat OpenAPI et clients générés

Les contrats REST métier sont pilotés par un **contrat OpenAPI**, et les clients - frontend comme service à
service - sont **générés depuis ce contrat**, jamais écrits à la main. Certains clients générés
embarquent un paquet de validation jumeau, ce qui fait valider le contrat des deux côtés du réseau.

Corollaire : modifier une réponse d'API sans régénérer les clients casse silencieusement les appelants. Le
contrat est l'artefact à changer en premier.

## Appels de service à service

Un service qui appelle un autre service interne s'authentifie par un **jeton machine à machine Auth0**
(flux client credentials), avec une **audience par backend cible**. Le jeton est acquis automatiquement par
le wrapper HTTP partagé, jamais par un échange de jeton codé à la main dans le service appelant.

Les jetons ainsi obtenus sont mis en cache, typiquement dans une table partagée dédiée à l'état éphémère,
avec rafraîchissement avant expiration.

## Nommage des domaines

Chaque microservice est exposé sur un **sous-domaine par domaine métier**, de la forme
`<stage>.<domaine>.api.salomon.com`, géré par un plugin Serverless dédié. Les domaines rencontrés
incluent `core` et `product`.

## Deux API plateforme centralisées

Ce sont des dépendances transverses, à connaître avant de recoder leur fonction localement.

**Le service d'idempotence**, sous `/idempotences` du domaine `core`. Un producteur lui soumet un
identifiant d'entité, un type et le contenu, et apprend si le payload a réellement changé depuis la
dernière fois. Sert à éviter une publication S/Bus inutile.

Son mode de panne est documenté et **assumé** : si le service est indisponible, le repli est
« considérer que ça a changé », donc republier. Risque de double publication connu, préféré à une
perte de message. À citer tel quel plutôt que de le présenter comme un bug.

**Le service d'autorisations**, sous `/authorizations` du domaine `core`. Rend des habilitations typées
par identifiant d'utilisateur et par code d'application. C'est le moyen standard d'enrichir une session
Auth0 côté frontend, **plutôt que d'encoder des rôles dans le JWT**.

## Deux points à ne pas combler par invention

**Le nommage des routes n'est pas homogène côté services.** Les préfixes observés diffèrent : certains
services exposent sous `/api/v1/...`, d'autres sous `/v1/...`, les callbacks de bus sous un préfixe encore
différent. Aucune règle n'est documentée dans les dépôts. Une convention peut exister au niveau de l'APIM
Platform sans être visible d'ici : demander à l'équipe Platform plutôt que d'affirmer qu'il n'y en a pas.

**La gouvernance des contrats est outillée mais son processus n'est pas documenté.** La validation de
schéma et la génération de clients existent comme mécanismes. Qui approuve un changement de schéma,
comment on versionne un contrat, comment on annonce une rupture : rien n'est écrit dans les dépôts. Même
réserve que ci-dessus, l'APIM Platform peut porter une partie de la réponse.

## Ce que ce skill ne sait pas

Tout ce qui concerne l'APIM interne : routage, politiques d'exposition, quotas, publication externe. C'est
le domaine de l'équipe Platform.

Et côté service : les adresses IP des allowlists, les audiences par environnement, les durées de cache, les
versions de paquets, les noms de fichiers d'authorizer, la liste des endpoints d'un service donné. Tout
cela se lit dans le dépôt.
