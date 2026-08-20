---
name: ecosystem-map
description: Carte de l'écosystème produit PDP (Product Data Platform) Salomon / Amer Sports - quel système fait foi sur quelle donnée, à quoi sert chaque application, ce qui est dans le périmètre PDP et ce qui en sort. À consulter en tout début de raisonnement sur une donnée produit, un asset, un assortiment, une taille, un code-barres ou la traçabilité, et dès qu'une question commence par « qui fait foi sur », « qu'est-ce qui alimente » ou « où se décide ».
---

# Carte de l'écosystème PDP

PDP signifie **Product Data Platform**. Le périmètre couvre la donnée produit et sa circulation entre les
SaaS et les microservices AWS de Salomon / Amer Sports.

Ce skill est le point d'entrée : il oriente. Il ne contient **aucun nom de topic ni liste de
souscriptions**, parce que ces deux choses sont renommées et modifiées au fil des sprints (voir le skill
`sbus`). Ce qui est stable et donc ici : **qui fait foi sur quoi**, et **à quoi sert chaque brique**.

## Qui fait foi sur quoi

La question la plus utile et la plus difficile à reconstituer. Se tromper de système autoritaire fait
écrire une story qui demande à la mauvaise équipe de changer la mauvaise donnée.

| Donnée | Système autoritaire | Précision |
|---|---|---|
| Produit consolidé, attributs modèle / article / SKU | **Salsify** (PIM) | référentiel consolidé qu'interrogent les avals, alimenté en amont par le PLM |
| Master data PLM brut : hiérarchie, type de développement | **PLM** (Centric, Plasma) | voir le paysage PLM plus bas |
| Prix, stock, données « chaudes » | **SAP** | affirmé mais non détaillé dans le périmètre documenté |
| Code-barres | **microservice `bar-code-generator`** | c'est lui qui génère ; il entre ensuite dans l'écosystème par le bus |
| Asset digital : fichier, métadonnées, renditions | **Aprimo** (DAM) | remplace Adobe Experience Manager, encore servi en legacy par un proxy |
| Décision d'assignation asset / produit / canal | **le service d'auto-assignation d'assets** | **pas Aprimo.** Aprimo détient l'asset, il ne décide pas quels assets conviennent à un produit et à un canal |
| Attributs d'asset Aprimo enrichis depuis le PIM | **le service de synchronisation PIM vers DAM** | pousse vers Aprimo, ne lit jamais Salsify en direct : il passe par le bus |
| Assortiment et visibilité B2B, preorder et reorder | **Merch Aggregator v2** | les champs composants restent propriété de leurs sources : le drop vient de SAP, le type de développement du PLM, la donnée produit du PIM, la sélection de gamme du GRM |
| Assortiment et visibilité D2C / ECOM | **Merch Aggregator v1** | legacy, migration vers v2 prévue |
| Assortiment Marketplace | **Merch Aggregator v2** | |
| Sélection de gamme preorder | **GRM** | système externe |
| Glossaire et définitions de propriétés PIM | **Salsify** | diffusé vers Aprimo comme classifications |
| Traçabilité, passeport numérique produit | **Atma.io** | fait foi sur le **document assemblé**, pas sur les données sources qu'il agrège |
| **Conversion de tailles** | **aucun système PDP** | voir la frontière ci-dessous |

## Une frontière à connaître : la conversion de tailles sort du périmètre

La conversion de tailles est obtenue en **appelant un microservice de l'ECOM**, au moment de la
publication des channels dans le connecteur sortant Salsify.

**Ce microservice est hors périmètre PDP.** Conséquence pour une story ou une étude : un besoin
d'évolution sur la conversion de tailles n'est pas un sujet PDP, il se négocie avec l'équipe ECOM. Aucun
système PDP n'en est autoritaire, et présenter Salsify comme la source de vérité des tailles converties
serait faux.

## Le paysage PLM

Trois noms circulent, et ce ne sont pas des synonymes :

- **Centric** : PLM en place.
- **Plasma** : PLM en place également. Centric et Plasma sont les deux PLM du paysage actuel.
- **OnePlm** : également basé sur Centric, mais en mode SaaS. **Pas encore déployé.** Ne pas le décrire au
  présent ni le supposer disponible.

## À quoi sert chaque brique

Rôles stables. Les noms de dépôt sont donnés pour l'orientation ; ce qui compte est la fonction.

**Autour du PIM Salsify.** Un connecteur **entrant** écrit dans Salsify ce qui arrive par le bus (master
data PLM, assortiment, assignation d'assets, code-barres) et ne publie jamais sur le bus. Un connecteur
**sortant** exporte les channels Salsify, publie les catalogues produit ainsi que les référentiels
associés, et porte le mécanisme de rejeu. Le connecteur sortant est autoritaire sur le dernier instantané
publié par catalogue et par locale, pas sur la donnée produit elle-même.

**Autour du DAM.** Le service d'**auto-assignation d'assets** calcule par règles quels assets Aprimo
assigner à un produit pour un couple demandeur / cible, avec ordre et repli. Le service de
**synchronisation PIM vers DAM** pousse les métadonnées produit dans les attributs d'asset Aprimo ; il est
terminal, il ne publie rien sur le bus.

**Deux connecteurs Aprimo coexistent, ce n'est pas une redondance.** Le connecteur **legacy** (le `l` de
son nom signifie legacy) **imite le comportement de l'ancien DAM Adobe Experience Manager** pour les
anciens consommateurs d'assets, qui n'ont pas été migrés. Le connecteur **nouveau** cible Aprimo, le
nouveau DAM. Ne pas confondre les deux, ni « corriger » l'un en l'autre.

**Les ponts de bus.** Des services sans état traduisent des messages du bus amont vers le S/Bus. L'un est
spécialisé master data PLM, l'autre est générique et piloté par configuration sur le périmètre PDP
(taille, code-barres, index technique). Un pont n'est autoritaire sur rien.

**Le Merch Aggregator, deux générations.** La v1 gère l'assortiment D2C / ECOM et est legacy, avec une
migration prévue vers la v2. La v2 gère l'assortiment B2B, preorder et reorder, ainsi que le pipeline
Marketplace. Une console frontend unique sert les deux plus le Marketplace.

**Le pont vers Atma.io.** Un connecteur sortant unique agrège traçabilité (expédition, produit
consommateur, commande d'achat), catalogue produit et assets, et les pousse vers Atma.io. Terminal, il ne
publie rien sur le S/Bus.

## Les zones que ce skill ne couvre pas

Honnêtement délimitées, pour éviter qu'une réponse soit inventée.

- Les **avals** ECOM, B2B au sens large, Data Platform et CRM n'ont pas de documentation d'architecture
  dans le périmètre : ils existent comme consommateurs, leur fonctionnement interne est inconnu d'ici.
- Le rôle exact de **SAP** sur prix et stock est affirmé, jamais détaillé.
- Le **GRM** n'est connu que par ce qu'il fournit.
- L'horizon de retrait du connecteur Aprimo legacy n'est pas fixé.
- Les consommateurs réels de chaque catalogue produit publié : c'est une information périssable, à lire
  dans le code du service ou dans la configuration des channels, pas ici.
