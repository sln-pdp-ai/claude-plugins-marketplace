<#
.SYNOPSIS
    Hook SessionStart : injecte la doctrine du workbench et l'etat du perimetre.

.DESCRIPTION
    Un plugin ne peut pas livrer de CLAUDE.md : le fichier n'est pas charge comme
    contexte de projet. Ce hook est le seul moyen de rendre la doctrine
    permanente plutot que dependante du chargement d'un skill.

    Aucun acces reseau ici : un fetch au demarrage bloquerait la session quand le
    VPN est coupe. Le controle de fraicheur reel est fait par les skills, via
    pdp-repos.ps1 -Action check.

    Sortie volontairement compacte : douze checkouts detailles a chaque demarrage
    noieraient la doctrine, qui est la vraie raison d'etre de ce hook. Le detail
    est a un appel de script.
#>
[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'pdp-lib.ps1')

$hook = Read-PdpHookInput
$cwd = if ($hook -and $hook.PSObject.Properties['cwd']) { $hook.cwd } else { (Get-Location).Path }

$lines = @()
$lines += '## Doctrine pdp-po-workbench (plugin, non negociable)'
$lines += ''
$lines += '- Les livrables sont du Markdown a coller dans Jira ou Confluence. Ce plugin n''ecrit jamais dans Atlassian : un livrable passe par un fichier relu et versionne, jamais directement dans un ticket. Bloque techniquement par un hook PreToolUse.'
$lines += '- Ancrage upstream obligatoire : des qu''une story ou une study touche un flux S/Bus entrant ou sortant, la regle concernee cite le quadruplet (systeme amont, topic + toState/filter, chemin complet du handler, cible d''ecriture). Un mot metier ("master data", "PLM", "catalog") ne prouve JAMAIS quel handler est vise.'
$lines += '- Le chemin du handler cite se verifie dans le checkout avant d''etre ecrit. Une story ancree sur un handler qui n''existe plus est fausse sans le dire.'
$lines += '- Les checkouts sont des sources en lecture seule. Aucune ecriture, aucun commit, aucun git mutant : ce sont les depots des equipes de dev. Bloque par le meme hook.'
$lines += '- knowledge/ est derive du code, pas ecrit a la main : il se regenere par la synchro. Ne pas y ajouter un fait a la main sans le dire, il sera ecrase.'
$lines += '- Le savoir d''architecture stable (S/Bus, exposition d''API, feature flags, journalisation, persistance, carte des systemes) vit dans le plugin pdp-architecture, pas ici. S''il est installe, ses skills se declenchent d''eux-memes ; ne pas recopier son contenu dans un livrable, le citer.'
$lines += '- Conventions de redaction : anglais obligatoire pour les livrables, jamais le tiret quadratin ni les points de suspension en un caractere, S/Bus ou Salomon Bus jamais "enterprise bus", numerotation des Rules strictement sequentielle sans "bis".'
$lines += '- Exception assumee : les fichiers d''ideation sous work-in-progress/<projet>/ideation/ sont du brouillon libre. Les conventions ci-dessus ne s''y appliquent pas, et le texte brut de l''utilisateur ne se corrige jamais.'
$lines += ''

$slugs = @(Get-PdpProjectSlugs)
$repos = @(Resolve-PdpCheckouts -Project 'all' -Cwd $cwd)
$present = @($repos | Where-Object { $_.Present })
$missing = @($repos | Where-Object { -not $_.Present })

$lines += '## Perimetre vu depuis ce projet'
$lines += ''
$lines += ("- Projets au manifeste ({0}) : {1}" -f $slugs.Count, ($slugs -join ', '))
$lines += ("- Checkouts resolus : {0} sur {1}" -f $present.Count, $repos.Count)

if ($present.Count -gt 0) {
    $managed = @($present | Where-Object { $_.Managed }).Count
    $own = $present.Count - $managed
    $lines += ("  dont {0} clone(s) de travail geres par le plugin et {1} depot(s) que vous gerez vous-meme" -f $managed, $own)
}
if ($missing.Count -gt 0) {
    $byProject = $missing | Group-Object -Property Project | ForEach-Object { "$($_.Name) ($($_.Count))" }
    $lines += ("- Checkouts absents : {0}" -f ($byProject -join ', '))
    $lines += '  Un checkout absent interdit l''ancrage upstream sur son projet. Le provisionner avec pdp-repos.ps1 -Action ensure -Project <slug>, apres l''avoir annonce.'
}

$lines += ''
$lines += 'Detail par checkout : pdp-repos.ps1 -Action paths. Fraicheur reelle (acces reseau) : -Action check -Project <slug>. Aucune fraicheur n''est verifiee au demarrage.'

Write-Output ($lines -join "`n")
exit 0
