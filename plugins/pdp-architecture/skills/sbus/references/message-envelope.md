# Enveloppe de message S/Bus, champ par champ

Référence détaillée de l'enveloppe. Le noyau et les trois pièges principaux sont dans le `SKILL.md` ;
cette page sert quand la question porte sur un champ précis ou demande un exemple complet.

Les noms de topics et d'applications qui apparaissent dans les exemples ci-dessous sont là pour montrer
la **forme** de l'enveloppe. Ils sont renommés au fil des sprints : ne jamais les reprendre comme noms
courants, les vérifier dans le code du service concerné.

## Champs de l'enveloppe

| Champ | Rôle | Se propage lors d'un rejeu ? |
|---|---|---|
| `context.env` | environnement logique (`QUAL`, `PROD`, ...) | oui |
| `context.application` | application émettrice du message | non, le producteur met la sienne |
| `context.uuid` | identifiant unique de ce message précis | non, un nouvel UUID est généré |
| `context.postedDate` | horodatage de la publication de ce message | non, horodatage du rejeu |
| `context.correlationId` | identifiant de corrélation, clé de reconnaissance du rejeu | **oui, obligatoire** |
| `context.systemOrigin` | système à l'origine de la demande, utile quand la publication est déclenchée depuis une console d'opérateur au nom d'une application aval | non |
| `context.version` | version du contrat, souvent `null` | selon le contrat |
| `context.priority` | priorité de traitement, souvent `null` | selon le contrat |
| `topic` | nom du topic de publication | non, la demande porte le topic `-request`, la réponse le topic standard |
| `entityNaturalId` | identifiant métier de l'entité portée (code article, par exemple). `null` sur une demande de rejeu | renseigné sur la réponse |
| `entityUpdatedDate` | dernière mise à jour de l'entité **dans le système source**. `null` sur une demande | **oui, préservé de l'événement d'origine** |
| `onlyTo` | ciblage de la livraison. Sur une demande : restreint quel producteur traite. Sur une réponse : restreint quel consommateur reçoit | résolu par la règle 7, pas recopié |
| `params` | paramètres libres | non |
| `content` | payload métier sur un topic standard, critères de filtre sur un topic `-request` | reconstruit depuis la persistance |

## Le double `onlyTo`, à ne pas confondre

Deux champs portent ce nom et leurs rôles sont opposés.

**`onlyTo` au niveau enveloppe d'une demande.** Restreint quelles applications amont doivent traiter la
demande. Utile quand plusieurs producteurs partagent un espace de noms de topics. N'a **aucun** effet sur
le ciblage de la réponse.

**`content.onlyTo` au niveau payload d'une demande.** Override optionnel du ciblage de la réponse. Quand
il est présent, le producteur l'utilise tel quel comme `onlyTo` de chaque message republié, à la place de
`context.application`. Trois usages : un rejeu déclenché par un opérateur depuis la console et qui doit
atterrir chez un consommateur précis, un rejeu redirigé vers une application sœur, une diffusion large
avec `null` pour désactiver le ciblage par message.

Règle de résolution, côté producteur :

```
responseOnlyTo = content.onlyTo si la clé est présente, sinon context.application
```

`content.onlyTo` à `null` est un opt-out **explicite** : la clé est présente, sa valeur est `null`, donc
elle gagne et le message part sans ciblage. Ce n'est pas la même chose qu'une clé absente.

## Exemple : demande de rejeu publiée par l'aval

```json
{
  "context": {
    "env": "QUAL",
    "application": "sln-salsify-out-connector",
    "uuid": "3792daee-0e94-4a8b-9ae2-55ea15c42ee6",
    "postedDate": "2026-03-20T10:58:25.443+01:00",
    "correlationId": "d5c05d73-805e-4fd0-a965-331a0fa03f90",
    "systemOrigin": "salomon-bus-support-console",
    "version": null,
    "priority": null
  },
  "topic": "pim-product-catalog-aaa-request",
  "entityNaturalId": null,
  "entityUpdatedDate": null,
  "onlyTo": "sln-salsify-out-connector",
  "params": null,
  "content": {
    "locale": "en-US"
  }
}
```

Lecture de cet exemple : la demande vise le producteur `sln-salsify-out-connector` via le `onlyTo`
d'enveloppe, elle filtre sur la locale `en-US`, et comme `content.onlyTo` est absent le producteur
ciblera ses réponses sur `context.application`.

## Exemple : message republié par l'amont

```json
{
  "context": {
    "env": "QUAL",
    "application": "sln-salsify-out-connector",
    "uuid": "8f24a3c7-1a2b-4c5d-9e8f-7b6a5c4d3e2f",
    "postedDate": "2026-03-20T10:58:26.123+01:00",
    "correlationId": "d5c05d73-805e-4fd0-a965-331a0fa03f90",
    "systemOrigin": "sln-salsify-out-connector",
    "version": null,
    "priority": null
  },
  "topic": "pim-product-catalog-aaa",
  "entityNaturalId": "L41681700",
  "entityUpdatedDate": "2026-03-15T08:12:00.000Z",
  "onlyTo": "salomon-bus-support-console",
  "params": {},
  "content": {
    "articleCode": "L41681700",
    "locale": "en-US",
    "productName": "Example Product"
  }
}
```

Lecture de cet exemple : le `correlationId` est identique à celui de la demande, l'`uuid` est neuf,
`postedDate` est l'horodatage du rejeu, `entityUpdatedDate` conserve la date de l'événement d'origine, et
`onlyTo` vaut ici `salomon-bus-support-console` parce que c'est le `context.application` de la demande.

## Critères de filtre courants dans `content`

Le schéma de `content` sur un topic `-request` est défini par le producteur et documenté dans son
contrat. Les formes qui reviennent :

| Intention | Forme |
|---|---|
| Filtre de locale | `{ "locale": "fr-FR" }` |
| Canal et locale | `{ "channel": "ecom", "locale": "fr-FR" }` |
| Liste d'articles | `{ "articleCode": ["L41681700", "L41681800"] }` |
| Plage de dates | `{ "updatedAt": { "$gte": "2026-03-01", "$lt": "2026-04-01" } }` |
| Rejeu total | `{}` |
| Estimation sans publication | `{ "dryRun": true }` |
| Redirection de la réponse | `{ "onlyTo": "sln-autre-consommateur" }` |

Ces formes sont indicatives. Les clés réellement acceptées par un producteur donné se lisent dans son
contrat ou dans son code, pas ici.
