---
name: persistence
description: Choix du datastore dans les microservices PDP - DynamoDB par défaut, MongoDB pour la donnée métier interrogeable, S3 pour l'échange de fichiers volumineux uniquement, et les DynamoDB Streams comme colle d'intégration interne à un service. À consulter dès qu'une conversation touche le stockage d'une donnée, le choix entre DynamoDB et MongoDB, un bucket S3, un flux de Stream, ou la conception de la persistance d'un nouveau service.
---

# Persistance - quel datastore pour quel besoin

Trois datastores, trois usages nettement séparés. La séparation est cohérente sur l'ensemble des
microservices de l'écosystème, sans être écrite comme convention nulle part : elle se déduit de la
convergence des implémentations.

## DynamoDB, le défaut

**Toujours présent, quel que soit le service.** C'est le choix par défaut, et il couvre quatre usages :

- **Tables de transit** alimentées par écriture puis lues par un Stream, pour découpler deux étapes d'un
  même service.
- **Caches d'idempotence**, pour dédupliquer une relivraison.
- **État partagé à courte durée de vie** : jeton mis en cache, drapeau de bridage, marqueur de reprise.
- **Miroirs de référentiel simples**, quand la donnée est lue par clé et jamais interrogée par critère.

Un service qui n'a besoin que de ça n'a pas besoin de MongoDB, et plusieurs services documentent
explicitement son absence pour éviter qu'on en suppose un.

## MongoDB, la donnée métier interrogeable

Réservé à la donnée métier **riche et interrogeable par critère** : catalogue, assortiment,
configuration. Le signal qui justifie MongoDB est le besoin de requêter par autre chose qu'une clé, avec
des filtres composables, de la pagination, ou une structure de document profonde.

Adopté par les services de génération récente. Son absence dans un service ancien n'est pas un oubli à
corriger.

## S3, l'échange de fichiers uniquement

**Jamais de donnée structurée dans S3.** Deux usages seulement :

- **Import et export de fichiers volumineux**, via URL présignée, typiquement des tableurs manipulés par
  un opérateur depuis une console.
- **Transport d'un export SaaS.** Le SaaS ne pousse pas la donnée : il pousse une URL S3, et le connecteur
  va chercher le fichier. C'est le premier maillon du flux d'ingestion le plus courant de l'écosystème.

Les buckets temporaires portent une règle de cycle de vie qui expire les objets ; un bucket d'archive à
conservation longue est distinct. Ne pas confondre les deux : écrire un objet destiné à durer dans un
bucket temporaire le fait disparaître en silence.

## Les DynamoDB Streams, colle d'intégration interne

À l'intérieur d'un microservice, le chaînage par défaut entre deux étapes est **l'écriture en table qui
déclenche l'étape suivante par Stream**, plutôt que l'appel synchrone de l'étape suivante par l'écrivain.

L'écrivain ne connaît pas son successeur, l'étape suivante rejoue à partir de la table si elle échoue, et
la table sert d'état intermédiaire observable.

Les consommateurs de Stream isolent l'échec partiel de lot : un enregistrement en échec ne fait pas
rejouer tout le lot. C'est un réglage de la source d'événements, pas du code applicatif.

## Ce qui est indépendant du datastore

La plomberie de reprise et de file de rebut des Lambdas alimentées par SQS est fournie par le plugin
Serverless interne, quel que soit le datastore derrière. Les conventions de reprise ne dépendent donc pas
du choix DynamoDB ou MongoDB.

## Ce que ce skill ne sait pas

Aucun nom de table, aucun index secondaire, aucune taille de lot, aucun TTL, aucun nom de bucket. Ces
éléments changent et se lisent dans le dépôt du service.

Le fait que cette répartition ne soit écrite nulle part comme règle mérite d'être dit quand la question
porte sur une **obligation** plutôt que sur un usage : ce skill décrit une convergence observée, pas une
politique imposée. Un service qui s'en écarte pour une bonne raison n'est pas en infraction.
