<#
.SYNOPSIS
    Hook SessionStart : injecte la doctrine SMT et l'etat des depots dans le contexte.

.DESCRIPTION
    Un plugin ne peut pas livrer de CLAUDE.md : le fichier n'est pas charge comme
    contexte de projet. Ce hook est le seul moyen de rendre la doctrine
    permanente plutot que dependante du chargement d'un skill.

    Aucun acces reseau ici : un fetch au demarrage bloquerait la session quand le
    VPN est coupe. Le controle de fraicheur reel est fait par les skills, via
    smt-repos.ps1 -Action check.

    Copie synchronisee entre les plugins SMT : voir l'en-tete de smt-lib.ps1.
#>
[CmdletBinding()]
param(
    [ValidateSet('spec', 'code', 'all')][string]$Need = 'spec'
)

. (Join-Path $PSScriptRoot 'smt-lib.ps1')

$hook = Read-SmtHookInput
$cwd = if ($hook -and $hook.PSObject.Properties['cwd']) { $hook.cwd } else { (Get-Location).Path }

$lines = @()
$lines += '## Doctrine SMT (plugin, non negociable)'
$lines += ''
$lines += '- Fail-fast : des qu''une spec est floue, ambigue, incomplete ou contradictoire, STOP. Dire ce qui est flou, ou, pourquoi cela bloque. Ne jamais deviner ni combler par une hypothese.'
$lines += '- Une question ouverte du corpus (SMT-<MODULE>-OQ-<NN>) qui porte sur le sujet traite est un bloquant, pas une nuance.'
$lines += '- Le glossaire (solution-overview/glossary.md du corpus de specs) fait autorite sur tout terme. Reprendre sa formulation exacte, ne jamais inventer de definition.'
$lines += '- Le corpus de specs versionne est la source de verite. Confluence porte une livraison synthetique, derivee et datee : en cas d''ecart, le git fait foi.'
$lines += '- Aucune affirmation sans source : fichier:ligne, identifiant EARS, ou cle Jira.'
$lines += '- Lecture seule : ni ecriture Jira ou Confluence, ni modification du corpus de specs, ni commit. Les sorties sont des propositions.'
$lines += '- Fraicheur obligatoire avant toute lecture de spec et toute comparaison spec / code : un clone perime fait repondre faux avec des citations qui ont l''air sourcees.'
$lines += ''
$lines += '## Depots SMT vus depuis ce projet'
$lines += ''

$anyMissing = $false
foreach ($r in (Resolve-SmtRepos -Need $Need -Cwd $cwd)) {
    if ($r.Present) {
        $tag = if ($r.IsProjectRoot) { 'projet courant' } elseif ($r.Managed) { 'clone de travail' } else { 'depot local' }
        $lines += ("- {0} ({1}) : {2} [{3}, dernier fetch {4}]" -f $r.Name, $r.Role, $r.Path, $tag, (Get-SmtLastFetch -Path $r.Path))
    }
    else {
        $anyMissing = $true
        $lines += ("- {0} ({1}) : ABSENT. Attendu dans {2}." -f $r.Name, $r.Role, $r.ExpectedPath)
    }
}

$lines += ''
if ($anyMissing) {
    $lines += 'Un depot absent bloque les skills SMT. Le provisionner avec le script du plugin (smt-repos.ps1 -Action ensure) apres l''avoir annonce, ou pointer un checkout existant via la variable d''environnement indiquee dans le README du plugin.'
}
$lines += 'La fraicheur affichee ici n''est pas verifiee (aucun acces reseau au demarrage). Avant de conclure, lancer smt-repos.ps1 -Action check.'

Write-Output ($lines -join "`n")
exit 0
