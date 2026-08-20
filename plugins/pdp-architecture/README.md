# pdp-architecture

Le savoir d'architecture **stable** de l'écosystème produit PDP Salomon / Amer Sports, distribué comme
contenu. Écrit à la main, relu, versionné. Utile à un PO qui rédige une story comme à un dev qui code :
un dev sait ce que fait son service, il ne sait pas ce que les autres attendent de lui.

## Installation

```
/plugin marketplace add https://gitlab.amersports.com/pdp/ai/claude-plugins-marketplace.git
/plugin install pdp-architecture@pdp-ai
```

Si l'installation annonce `Run /reload-plugins to activate`, lancer `/reload-plugins`.

Rien d'autre à faire. Pas d'authentification, pas de dépôt à cloner, pas de variable d'environnement.

## Ce que le plugin apporte

| Skill | Sujet |
|---|---|
| `ecosystem-map` | qui fait foi sur quelle donnée, à quoi sert chaque brique, ce qui sort du périmètre PDP. Point d'entrée |
| `sbus` | S/Bus : nommage des topics, enveloppe de message, pattern replay via topic `-request`, propagation du `correlationId`, ciblage par `onlyTo` |
| `api-exposure-auth` | l'APIM interne de l'équipe Platform en amont, puis dans le service : authorizer Auth0 et IDP, allowlist IP des webhooks SaaS, validation de schéma, contrat OpenAPI, jetons machine à machine |
| `feature-flags` | AWS AppConfig via le client partagé : triplet de résolution, contrat de repli obligatoire, où placer le gate, provisionnement |
| `structured-logging` | `sln-logger` : pourquoi un payload interpolé n'est jamais paresseux, masquage des clés sensibles, `JsonLogger` contre `Logger` |
| `persistence` | quel datastore pour quel besoin : DynamoDB par défaut, MongoDB pour l'interrogeable, S3 pour les fichiers, Streams comme colle interne |

Les skills se déclenchent **d'eux-mêmes** quand la conversation touche leur sujet. Rien à invoquer. Pour
forcer la lecture d'un skill précis : `/pdp-architecture:sbus`.

Chaque skill porte l'essentiel dans son `SKILL.md` et le détail dans des fichiers de référence à côté,
lus seulement quand la question les appelle.

## Ce que le plugin ne contient pas, volontairement

Aucun chemin de fichier, aucun nom de handler, aucune constante, aucune version de package, aucun SHA.

Ces éléments changent à chaque sprint. Figés dans un plugin publié tous les trois mois, ils seraient faux
sans que personne ne s'en aperçoive, et une story écrite dessus serait fausse aussi. La règle du domaine
est que le code fait foi : ce plugin porte ce que le code ne dit pas, pas une copie périmée de ce qu'il
dit.

Concrètement, ce plugin sait que « le producteur souscrit au topic `-request` et republie sur le topic
standard ». Il ne sait pas quel fichier le fait, ni avec quelle taille de page. Pour cela, il faut lire
le dépôt.

Ne contient pas non plus les conventions de rédaction des livrables Jira et Confluence : elles
appartiennent à `pdp-po-workbench`. Ce plugin fournit la matière métier, pas la mise en forme.

## Périmètre

Le plugin est en lecture seule par nature : il n'a ni script, ni hook, ni serveur MCP. Il n'exécute rien
et n'écrit rien. Il ajoute du contenu au contexte, c'est tout.

Conséquence agréable : contrairement aux plugins `smt-*`, il fonctionne sur macOS et Linux autant que sur
Windows, puisqu'il ne dépend d'aucun script PowerShell.

## Limites connues

- **Couverture partielle.** Six skills à ce stade. Restent à écrire : la stack Serverless et ce que le
  plugin interne provisionne, et les patterns de résilience récurrents des microservices. Les avals
  ECOM / B2B / Data Platform / CRM n'ont pas de documentation d'architecture exploitable, `ecosystem-map`
  le dit explicitement plutôt que de combler.
- **Le contenu vieillit quand même**, plus lentement. Les invariants restent, la carte des applications
  bouge. Relire à chaque PI planning plutôt que jamais.
- **Aucune vérification automatique.** Rien ici ne contrôle que le contenu correspond encore au code.
  C'est le prix de l'absence de mécanique, et la raison pour laquelle les faits périssables en sont
  exclus.
