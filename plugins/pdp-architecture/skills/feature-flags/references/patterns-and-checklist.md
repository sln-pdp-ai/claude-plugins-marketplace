# Feature flags - cas d'usage et check-list

Complément du `SKILL.md`. Les quatre usages pour lesquels un flag AppConfig est le bon outil, la
check-list avant fusion, et ce qui reste ouvert.

## Les quatre usages éprouvés

**Bascule d'un topic S/Bus sans redéploiement.** Un consommateur doit migrer d'un ancien topic vers un
nouveau. Les deux souscriptions restent déclarées statiquement, le flag choisit lequel des deux chemins
s'exécute. C'est le cas canonique : il découple le calendrier du producteur de celui du consommateur, ce
qu'aucun déploiement coordonné ne permet de faire proprement.

**Ouverture d'un canal ou d'une fonctionnalité.** Une route de frontend ou une branche de traitement
n'est exposée que si son attribut vaut `true`. Le frontend n'interroge pas AppConfig directement : il
appelle un endpoint technique de son backend qui lui rend les flags résolus.

**Comportement spécifique à un environnement.** Sauter une publication sur le bus en `DEV` tout en
gardant le reste du pipeline fonctionnel, activer un log verbeux, contourner un aval indisponible. Le
flag porte un booléen et l'artefact déployé reste identique partout.

**Kill-switch et bridage.** Couper une consommation en urgence, ou gater le traitement des topics
`-request` quand une vague de rejeu est attendue et que les avals doivent d'abord se vider.

## Check-list avant de fusionner un service qui introduit un flag

- [ ] Application AppConfig créée par le script de provisionnement sur les quatre environnements.
- [ ] Nom du profil de configuration documenté dans le README du microservice.
- [ ] `defaultValue` posé en code, et **égal au comportement actuel et sûr**, pas au nouveau.
- [ ] Rôle IAM de la Lambda autorisé à ouvrir une session et lire la configuration sur l'ARN de
      l'application.
- [ ] TTL de cache cohérent avec le délai de propagation voulu.
- [ ] Log `WARN` de repli vérifié pour de vrai en `DEV`, en cassant volontairement la résolution.
- [ ] Pour un flag risqué en production : stratégie de déploiement progressive plutôt que `AllAtOnce`.
- [ ] Pour un flag à attributs : ce que vaut un attribut **absent** est décidé et écrit.

Le point le plus souvent négligé est l'avant-dernier : le repli n'est pas testé, et on découvre son
comportement le jour d'une panne AppConfig.

## Ordre de déploiement

Provisionner le flag, puis déployer les Lambdas. Dans l'ordre inverse, la première invocation ne trouve
pas son profil et part en repli, ce qui est correct fonctionnellement mais bruyant, et trompeur si
quelqu'un lit les logs à ce moment-là.

## Questions ouvertes sur le sujet

À signaler comme non tranchées plutôt que d'inventer une réponse.

- Existe-t-il un standard de stratégie de déploiement AppConfig à l'échelle de l'écosystème, progressive
  ou en une fois, ou reste-ce un choix par microservice ?
- Le client partagé devrait-il exposer une écoute des changements pour réagir entre deux invocations, ou
  le sondage par TTL suffit-il ?
- Où est la liste canonique des flags en usage sur tous les microservices ? Il n'y en a pas. Un registre
  central éviterait les collisions de noms.
