# Accès des profils non-dev

Note de cadrage. Aucune implémentation à ce stade ; la surface de distribution sera tranchée plus
tard.

## Besoin

Des profils non-dev (sans VSCode) veulent chatter avec l'assistant SMT sans récupérer ce projet ni
passer par l'extension Claude Code. Cas d'usage visés : comparer specs et sources, proposer des
refactorings, mettre à jour de la doc à partir des sources.

## Principe

Le projet = trois briques : les instructions (`CLAUDE.md`), les connexions outils (MCP Atlassian +
accès GitLab), et le code. La surface de chat est interchangeable. Le `.mcp.json` ne vaut que pour
Claude Code ; sur claude.ai et Slack, on utilise des Connecteurs (même MCP, configuré au niveau
compte/org). Les non-devs ne clonent donc jamais ce dépôt.

## Pistes

1. Claude.ai « Project » + Connecteurs : instructions du Project = `CLAUDE.md`, connecteur Atlassian
   déjà en place. Chat navigateur, zéro installation. Couvre Confluence/Jira. Manque le code GitLab.
2. Claude dans Slack : chatter via Slack et les connecteurs de l'org. Rapide si l'app Slack est
   déployée. Même angle mort GitLab.
3. Assistant hébergé (Claude Agent SDK / Managed Agents) : service central, system prompt =
   `CLAUDE.md`, outils = Atlassian + code GitLab read-only, front web ou Slack, identifiants
   centralisés. Couvre l'ensemble, specs-vs-code inclus. Nécessite build + hébergement + revue sécu.
4. Débloquer l'accès code (transverse) : (a) MCP GitLab officiel activé par l'admin, branché comme
   connecteur ; (b) MCP communautaire + PAT read-only ; (c) clones read-only côté serveur.

## Décisions (2026-07-29)

- Distribution non-dev : à décider plus tard (piste non tranchée).
- Accès code sans clone, préférence retenue : clones read-only côté serveur (option 4c), cohérent
  avec l'approche checkout local et le fait que le MCP GitLab officiel n'est pas activé sur
  l'instance.
- Court terme conseillé : Piste 1 (Claude.ai Project) pour tout le volet Confluence/Jira.

## Gouvernance

Accès en lecture seule, sorties en proposition (pas d'écriture). Données dans le tenant Amer Sports.
Pas de PII ni de données sensibles dans les sorties ou artefacts.
