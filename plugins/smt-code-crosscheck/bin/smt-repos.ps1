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
    update : rafraichit (git pull --ff-only) les seuls clones de travail geres par
             le plugin. Ne touche jamais un depot gere par l'utilisateur (projet
             courant, repos/, depot frere, variable d'environnement) : celui-la
             reste le sien.

.PARAMETER Need
    spec (defaut) : le corpus de specs seul. code : les deux depots de code.
    all : les trois.

.EXAMPLE
    powershell -File bin/smt-repos.ps1 -Action check -Need all
#>
[CmdletBinding()]
param(
    [ValidateSet('paths', 'check', 'ensure', 'update')][string]$Action = 'paths',
    [ValidateSet('spec', 'code', 'all')][string]$Need = 'spec',
    [switch]$NoFetch,
    [string]$Cwd
)

. (Join-Path $PSScriptRoot 'smt-lib.ps1')

$repos = @(Resolve-SmtRepos -Need $Need -Cwd $Cwd)
$problems = 0

$gitignoreHint = $null
if (@($repos | Where-Object { -not $_.Present }).Count -gt 0) {
    $gitignoreHint = Test-SmtGitignoreAdvice -Cwd $Cwd
}

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
        if ($gitignoreHint) {
            Write-Output ''
            Write-Output "ASTUCE : ce projet est un depot git qui n'ignore pas .smt-tmp. Sans cette entree, -Action ensure clonera dans le cache utilisateur (%LOCALAPPDATA%) au lieu du projet. Ajouter '.smt-tmp/' a $gitignoreHint avant de lancer -Action ensure pour garder le clone local."
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
            Write-Output "Clone de travail perime : proposer -Action update. Depot gere par vous : rafraichir a la main, git -C <chemin> pull --ff-only. Depot absent : -Action ensure."
        }
        if ($gitignoreHint) {
            Write-Output ''
            Write-Output "ASTUCE : ce projet est un depot git qui n'ignore pas .smt-tmp. Sans cette entree, -Action ensure clonera dans le cache utilisateur (%LOCALAPPDATA%) au lieu du projet. Ajouter '.smt-tmp/' a $gitignoreHint avant de lancer -Action ensure pour garder le clone local."
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

    'update' {
        foreach ($r in $repos) {
            if (-not $r.Present) {
                Write-Output ("{0,-20} ABSENT           rien a mettre a jour, voir -Action ensure" -f $r.Name)
                continue
            }
            if (-not $r.Managed) {
                Write-Output ("{0,-20} GERE PAR VOUS    non touche : rafraichir vous-meme, git -C {1} pull --ff-only" -f $r.Name, $r.Path)
                continue
            }

            $f = Invoke-Git @('-C', $r.Path, 'fetch', '--quiet')
            if (-not $f.Ok) {
                $problems++
                Write-Output ("{0,-20} FETCH ECHOUE     verifier le VPN et les droits GitLab" -f $r.Name)
                continue
            }

            $dirty = (Invoke-Git @('-C', $r.Path, 'status', '--porcelain')).Out
            if ($dirty) {
                $problems++
                Write-Output ("{0,-20} SALE             non touche : working tree non vide sur un clone gere, anormal" -f $r.Name)
                continue
            }

            $branch = (Invoke-Git @('-C', $r.Path, 'rev-parse', '--abbrev-ref', 'HEAD')).Out
            $upstream = (Invoke-Git @('-C', $r.Path, 'for-each-ref', '--format=%(upstream:short)', "refs/heads/$branch")).Out
            if ([string]::IsNullOrWhiteSpace($upstream)) { $upstream = 'origin/HEAD' }
            $behind = (Invoke-Git @('-C', $r.Path, 'rev-list', '--count', "HEAD..$upstream")).Out

            if ($behind -eq '0') {
                Write-Output ("{0,-20} DEJA A JOUR      {1}" -f $r.Name, $r.Path)
                continue
            }

            $p = Invoke-Git @('-C', $r.Path, 'pull', '--ff-only', '--quiet')
            if ($p.Ok) {
                Write-Output ("{0,-20} MIS A JOUR       {1} commit(s) recupere(s)" -f $r.Name, $behind)
            }
            else {
                $problems++
                Write-Output ("{0,-20} PULL ECHOUE      fast-forward impossible, intervention manuelle necessaire sur {1}" -f $r.Name, $r.Path)
            }
        }
    }
}

if ($problems -gt 0) { exit 1 }
exit 0
