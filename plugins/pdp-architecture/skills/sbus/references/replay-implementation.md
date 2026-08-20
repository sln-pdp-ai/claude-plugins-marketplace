# Implémenter le rejeu dans un producteur

Pattern d'implémentation côté producteur. Décrit la forme de la solution, pas le code d'un service
précis : les chemins, les noms de handler et les constantes se lisent dans le dépôt concerné.

## Ce qu'il faut provisionner

| Élément | Pourquoi |
|---|---|
| Souscription S/Bus au topic `-request` | déclenche le traitement de la demande |
| Droits IAM de publication sur le topic standard | déjà présents si le producteur publie des événements |
| Accès en lecture à la persistance qui alimente le topic standard | source du rejeu |
| Table d'idempotence | optionnelle, déduplique les relivraisons d'une même demande |
| Workers de reprise pour les étapes longues | pagination de la persistance, publication par lots |

La souscription ne se déclare pas en événement `sqs:` brut dans le manifeste Serverless. Elle passe par
le plugin Serverless interne, qui découvre les topics souscrits dans le code des handlers et provisionne
les files et les DLQ. Les workers de reprise, eux, se déclarent dans le manifeste : chacun devient une
Lambda alimentée par sa propre file.

## Le traitement d'une demande, étape par étape

1. **Lire la demande** : extraire `content` (critères de filtre et override éventuel), et dans `context`
   le `correlationId` et l'`application`.
2. **Résoudre la cible de réponse** avant toute autre chose :
   `responseOnlyTo = content.onlyTo si la clé est présente, sinon context.application`. Traiter
   `content.onlyTo: null` comme un opt-out explicite, donc une diffusion large.
3. **Valider les filtres** : rejeter la demande sans interroger la persistance si une clé obligatoire
   manque. Rejeter, pas interpréter : un filtre obligatoire absent n'est pas un rejeu total.
4. **Construire la requête** en combinant le périmètre canonique du producteur, qui s'applique toujours,
   avec les filtres de la demande, qui s'ajoutent par dessus.
5. **Parcourir les résultats** et reconstruire pour chacun le payload du flux normal.
6. **Publier sur le topic standard**, en recopiant le `correlationId` de la demande et en posant le
   `responseOnlyTo` résolu à l'étape 2 sur chaque message.
7. **Journaliser** la demande, la cible résolue, le nombre d'enregistrements correspondants et le
   `correlationId`, pour que le rejeu soit traçable a posteriori.

## Le découpage en deux workers

Un rejeu peut porter sur un volume arbitraire. Le pattern éprouvé de l'écosystème sépare deux
préoccupations en deux workers distincts, chacun alimenté par sa file.

**Worker de pagination.** Traite une page de la persistance, envoie les enregistrements au worker de
publication, puis se ré-enfile lui-même avec la page suivante s'il en reste une. La durée de chaque
invocation reste bornée, ce qui rend le volume total indifférent : pas de plafond `limit` à choisir.

**Worker de publication.** Reçoit un lot d'enregistrements, les découpe en petits paquets et publie sur
le topic standard. Découple la pagination de la persistance de la contre-pression du bus.

Un producteur qui implémente le rejeu pour la première fois reprend cette structure à deux workers
plutôt que de tout faire dans le handler de la demande. Une boucle unique sur un gros volume finit en
timeout Lambda, et la reprise repart de zéro.

## Gestion d'erreur

| Situation | Comportement attendu |
|---|---|
| Demande mal formée : `content` absent, JSON invalide | journaliser un avertissement et abandonner le message. Ne rien republier |
| Clé de filtre obligatoire absente | rejeter sans interroger la persistance |
| Échec d'accès à la persistance : timeout, bascule de réplique | journaliser une erreur et laisser le message retourner en file pour reprise |
| Aucun enregistrement correspondant | journaliser un avertissement et terminer proprement, zéro message publié, aucune erreur levée |
| Volume susceptible de noyer l'aval | plafonner par demande et paginer, plutôt que de publier d'un bloc |

La complétion silencieuse sur zéro résultat est un invariant, pas une commodité : un rejeu qui ne trouve
rien est un résultat valide. Lever une erreur ferait repasser le message en file et boucler.

## Le mode `dryRun`

Le producteur peut accepter un `dryRun: true` optionnel dans `content`. Dans ce mode, il exécute la
requête normalement, journalise le nombre de résultats, et retourne sans publier aucun message.

Utile à un opérateur qui veut estimer le volume et le périmètre d'un rejeu avant de le déclencher pour de
vrai. Pas obligatoire sur tous les producteurs : à implémenter là où les rejeux sont volumineux ou
sensibles.

## Ce qui reste à vérifier dans le code

Ce document ne dit rien de ce qui suit, et ne peut pas le dire. À lire dans le dépôt du producteur
concerné.

- Les clés de filtre réellement acceptées, et lesquelles sont obligatoires.
- Le périmètre canonique du producteur, c'est-à-dire ses critères métier fixes.
- La taille des pages et des paquets de publication.
- Les noms des files et des workers.
- Si l'idempotence et le `dryRun` sont implémentés ou non.
