---
name: feature-flags
description: Feature flags dans l'écosystème produit PDP - AWS AppConfig via le client partagé sln-feature-flag-client, triplet de résolution application / environnement / profil, contrat de repli obligatoire, où placer le gate dans un handler abonné au S/Bus. À consulter dès qu'une conversation touche un feature flag, une bascule sans redéploiement, un kill-switch, un rollout progressif, un comportement conditionné par l'environnement, ou une migration producteur / consommateur étalée dans le temps.
---

# Feature flags - AWS AppConfig et `sln-feature-flag-client`

**AWS AppConfig est l'unique mécanisme de feature flag** de l'écosystème, accédé en code par le client
partagé `sln-feature-flag-client`. Pas de table de configuration maison, pas de variable
d'environnement détournée en interrupteur.

## Le triplet de résolution

Un flag se résout sur trois dimensions, et cette correspondance est la convention :

| Dimension AppConfig | Correspond à | Exemple |
|---|---|---|
| Application | le nom du microservice, identique au nom du service Serverless | `sln-salsify-in-connector` |
| Environnement | le stage de déploiement | `DEV`, `QUAL`, `PREPROD`, `PROD` |
| Profil de configuration | un flag, ou un groupe fonctionnel de flags | `b2b-listen-topic`, `marketplace` |

Une application AppConfig par microservice. Un profil par flag ou par groupe. Le stage est lu dans la
variable d'environnement de la Lambda, alimentée par Serverless.

Les valeurs sont mises en cache en mémoire dans le conteneur Lambda, avec un TTL (défaut : 60 secondes).
Conséquence opérationnelle : **une bascule se propage en au plus un TTL, sans redéploiement**, et le
retour arrière est symétrique par redéploiement de la version AppConfig précédente.

## Le contrat de repli, non négociable

`defaultValue` est **obligatoire à la construction**. Une revue de code rejette tout client construit
sans lui.

Toutes les défaillances retombent sur `defaultValue` avec un log `WARN` : application, environnement ou
profil absent, erreur réseau ou IAM, payload JSON malformé, sous-flag inconnu. Jamais de routage
silencieux vers un chemin non voulu, jamais d'exception qui traverse le handler.

Corollaire de conception : **`defaultValue` doit valoir le comportement sûr, c'est-à-dire l'actuel.** Un
défaut qui vaut le comportement nouveau transforme une panne AppConfig en mise en production
accidentelle.

Un pic de replis se lit dans les logs. Trois causes habituelles : un déploiement AppConfig en cours, une
régression de politique IAM sur le rôle de la Lambda, ou un profil supprimé.

## Où placer le gate

**Le flag gate la logique à l'intérieur d'un handler déjà abonné, jamais l'abonnement au bus.** Toutes
les souscriptions S/Bus restent déclarées statiquement ; le flag décide si le message est traité, ou
acquitté et jeté.

C'est ce qui permet de découpler le calendrier d'une migration : le producteur peut publier sur le
nouveau topic avant que le consommateur ne le traite, et l'inverse. Gater l'abonnement lui-même
obligerait à redéployer, ce qui annule l'intérêt du flag.

Le même principe vaut côté frontend : le frontend ne lit pas AppConfig, il interroge un endpoint
technique de son backend qui expose les flags résolus.

## Le variant « Basic flag » à attributs

Quand plusieurs interrupteurs indépendants doivent cohabiter, un seul profil porte une bascule maîtresse
plus un attribut booléen typé par dimension gérée : un par topic, un par couple demandeur / cible, un par
canal.

```json
{
  "marketplace.decathlon": true,
  "marketplace.amazon": false
}
```

La résolution passe alors le sous-flag en second argument. Ce variant garde l'artefact de déploiement
identique entre environnements, seule la valeur AppConfig diffère.

Piège de ce variant : un attribut **absent** n'est pas un attribut à `false` du point de vue du code,
c'est un sous-flag inconnu, donc un repli sur `defaultValue` avec un `WARN`. Décider explicitement ce que
vaut l'absence, et le documenter.

## Provisionner un flag

**La création manuelle dans la console AWS est interdite.** Chaque microservice embarque un script
TypeScript de provisionnement, paramétré par environnement, idempotent, qui crée ou met à jour
l'application, l'environnement, le profil et la version de configuration hébergée.

Le script s'exécute dans le pipeline de déploiement, **avant** le déploiement des Lambdas qui dépendent
du flag. Dans l'ordre inverse, la première invocation part en repli.

Le rôle IAM de la Lambda a besoin des droits de session et de lecture de configuration AppConfig sur
l'ARN de l'application. Un oubli se manifeste comme un repli permanent, pas comme une erreur de
déploiement.

## Stratégie de déploiement

`AllAtOnce` hors production. En production, rollout progressif recommandé pour un flag risqué.

Point non tranché à l'échelle de l'écosystème : il n'existe pas de standard imposé, le choix est par
microservice. Le signaler comme tel plutôt que de présenter un des deux comme la règle.

## Où aller ensuite

Les cas d'usage éprouvés, la check-list avant fusion et les questions ouvertes sont dans
[references/patterns-and-checklist.md](references/patterns-and-checklist.md).

## Ce que ce skill ne sait pas

Les noms de flags et de profils réellement déployés, service par service. Les exemples cités ici sont
illustratifs et peuvent avoir été renommés ou retirés. Il n'existe pas de registre central des flags en
usage, ce qui est un manque connu : pour savoir ce qui est actif sur un service, lire son code et sa
configuration AppConfig.

Aucune version de package n'est citée ici, volontairement.
