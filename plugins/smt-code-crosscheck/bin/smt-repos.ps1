<#
.SYNOPSIS
    Resout les depots SMT, controle leur fraicheur, provisionne ce qui manque.

.DESCRIPTION
    Point d'entree unique des skills du plugin. Une seule implementation du
    controle de fraicheur, un seul code de retour, une sortie normalisee.

    Copie synchronisee entre les plugins SMT : voir l'en-tete de smt-lib.ps1.

.PARAMETER Action
    paths  : ou se trouve chaque depot (aucun acces reseau).
    check  : fetch + verdict de fraicheur. Code de retour 1 si un depot bloque.
    ensure : clone les depots manquants dans le dossier tmp du projet courant.

.PARAMETER Need
    spec (defaut) : le corpus de specs seul. code : les deux depots de code.
    all : les trois.

.EXAMPLE
    powershell -File bin/smt-repos.ps1 -Action check -Need all
#>
[CmdletBinding()]
param(
    [ValidateSet('paths', 'check', 'ensure')][string]$Action = 'paths',
    [ValidateSet('spec', 'code', 'all')][string]$Need = 'spec',
    [switch]$NoFetch,
    [string]$Cwd
)

. (Join-Path $PSScriptRoot 'smt-lib.ps1')

$repos = @(Resolve-SmtRepos -Need $Need -Cwd $Cwd)
$problems = 0

switch ($Action) {

    'paths' {
        foreach ($r in $repos) {
            if ($r.Present) {
                $tag = if ($r.IsProjectRoot) { 'PROJET COURANT' } elseif ($r.Managed) { 'CLONE DE TRAVAIL' } else { 'DEPOT LOCAL' }
                Write-Output ("{0,-20} {1,-16} {2} [{3}]" -f $r.Name, $tag, $r.Path, $r.Origin)
            }
            else {
                $problems++
                Write-Output ("{0,-20} {1,-16} attendu dans {2}" -f $r.Name, 'ABSENT', $r.ExpectedPath)
            }
        }
    }

    'check' {
        foreach ($r in $repos) {
            $res = Test-SmtFreshness -Repo $r -NoFetch:$NoFetch
            if ($res.Verdict -ne 'A_JOUR') { $problems++ }
            Write-Output (Format-SmtLine -Result $res)
        }
        if ($problems -gt 0) {
            Write-Output ''
            Write-Output "STOP : $problems depot(s) non exploitable(s). Ne rien conclure sur un corpus ou un code absent, perime ou modifie."
            Write-Output "Rafraichir a la main : git -C <chemin> pull --ff-only. Provisionner un depot absent : -Action ensure."
        }
    }

    'ensure' {
        foreach ($r in $repos) {
            if ($r.Present) {
                Write-Output ("{0,-20} DEJA LA          {1}" -f $r.Name, $r.Path)
                continue
            }
            $parent = Split-Path -Parent $r.ExpectedPath
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Write-Output ("{0,-20} CLONE EN COURS   {1}" -f $r.Name, $r.ExpectedPath)
            & git clone --quiet $r.Url $r.ExpectedPath
            if ($LASTEXITCODE -eq 0) {
                Write-Output ("{0,-20} CLONE OK         {1}" -f $r.Name, $r.ExpectedPath)
            }
            else {
                $problems++
                Write-Output ("{0,-20} CLONE ECHOUE     verifier le VPN et les droits GitLab sur {1}" -f $r.Name, $r.Url)
            }
        }
    }
}

if ($problems -gt 0) { exit 1 }
exit 0
