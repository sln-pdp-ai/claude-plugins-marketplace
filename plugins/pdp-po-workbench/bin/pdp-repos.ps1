<#
.SYNOPSIS
    Resout les checkouts du domaine PDP, controle leur fraicheur, provisionne ce
    qui manque.

.DESCRIPTION
    Point d'entree unique des skills du plugin pour tout ce qui touche au code.
    Une seule implementation du controle de fraicheur, un seul code de retour,
    une sortie normalisee.

    Aucun skill ne doit deviner un chemin de checkout ni appeler git directement
    pour savoir ou en est un depot : tout passe par ce script.

.PARAMETER Action
    list   : le manifeste seul (projets, checkouts, branche, zones). Aucun acces
             disque, aucun acces reseau.
    paths  : ou se trouve chaque checkout sur ce poste. Aucun acces reseau.
    check  : fetch + verdict de fraicheur. Code de retour 1 si un checkout bloque.
    ensure : clone les checkouts manquants dans local-repos/ du projet courant.
    update : rafraichit (git pull --ff-only) les seuls clones de travail geres par
             le plugin. Ne touche jamais un depot gere par l'utilisateur (projet
             courant, depot frere, PDP_REPOS_DIR) : celui-la reste le sien.
    zones  : pour chaque checkout, la reference distante, son SHA et les globs de
             zones. C'est l'entree du sous-agent codebase-syncer.

.PARAMETER Project
    Un slug du manifeste, ou 'all' (defaut). Restreindre au projet traite : la
    synchro des huit projets coute cher pour rien quand la story n'en touche qu'un.

.EXAMPLE
    powershell -File bin/pdp-repos.ps1 -Action check -Project merch-aggregator
#>
[CmdletBinding()]
param(
    [ValidateSet('list', 'paths', 'check', 'ensure', 'update', 'zones')][string]$Action = 'paths',
    [string]$Project = 'all',
    [switch]$NoFetch,
    [string]$Cwd
)

. (Join-Path $PSScriptRoot 'pdp-lib.ps1')

$defs = @(Get-PdpProjectDefs -Project $Project)
if ($defs.Count -eq 0) {
    $known = (Get-PdpProjectSlugs) -join ', '
    Write-Output "PROJET INCONNU : '$Project' n'est pas dans le manifeste du plugin."
    Write-Output "Projets connus : $known"
    Write-Output "Un projet absent du manifeste n'a pas de checkout adosse : ne rien conclure sur son code."
    exit 1
}

$problems = 0

$gitignoreHint = $null
if ($Action -ne 'list') {
    $repos = @(Resolve-PdpCheckouts -Project $Project -Cwd $Cwd)
    if (@($repos | Where-Object { -not $_.Present }).Count -gt 0) {
        $gitignoreHint = Test-PdpGitignoreAdvice -Cwd $Cwd
    }
}

$hintText = "ASTUCE : ce projet est un depot git qui n'ignore pas local-repos. Sans cette entree, -Action ensure clonera dans le cache utilisateur (%LOCALAPPDATA%) au lieu du projet. Ajouter 'local-repos/' au .gitignore avant de lancer -Action ensure pour garder les clones dans le projet."

switch ($Action) {

    'list' {
        foreach ($d in $defs) {
            Write-Output ("{0} - {1} (branche {2})" -f $d.Slug, $d.Label, $d.Branch)
            foreach ($co in $d.Checkouts) {
                Write-Output ("    {0,-28} {1}" -f $co.Name, $co.Url)
            }
            Write-Output ("    savoir : {0}" -f ($d.Knowledge -join ', '))
        }
    }

    'paths' {
        foreach ($r in $repos) {
            if ($r.Present) {
                $tag = if ($r.IsProjectRoot) { 'PROJET COURANT' } elseif ($r.Managed) { 'CLONE DE TRAVAIL' } else { 'DEPOT LOCAL' }
                Write-Output ("{0,-28} {1,-12} {2,-16} {3} [{4}]" -f $r.Name, $r.Project, $tag, $r.Path, $r.Origin)
            }
            else {
                $problems++
                Write-Output ("{0,-28} {1,-12} {2,-16} attendu dans {3}" -f $r.Name, $r.Project, 'ABSENT', $r.ExpectedPath)
            }
        }
        if ($gitignoreHint) {
            Write-Output ''
            Write-Output $hintText
        }
    }

    'check' {
        foreach ($r in $repos) {
            $res = Test-PdpFreshness -Repo $r -NoFetch:$NoFetch
            if ($res.Verdict -ne 'A_JOUR') { $problems++ }
            Write-Output (Format-PdpLine -Result $res)
        }
        if ($problems -gt 0) {
            Write-Output ''
            Write-Output "ATTENTION : $problems checkout(s) non exploitable(s) en l'etat. Ne rien affirmer sur un code absent ou perime : une story ancree sur un handler qui n'existe plus est fausse sans le dire."
            Write-Output "Clone de travail en retard : proposer -Action update. Depot gere par vous : rafraichir a la main, git -C <chemin> fetch. Checkout absent : -Action ensure."
        }
        if ($gitignoreHint) {
            Write-Output ''
            Write-Output $hintText
        }
    }

    'ensure' {
        foreach ($r in $repos) {
            if ($r.Present) {
                Write-Output ("{0,-28} DEJA LA          {1}" -f $r.Name, $r.Path)
                continue
            }
            $parent = Split-Path -Parent $r.ExpectedPath
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Write-Output ("{0,-28} CLONE EN COURS   {1}" -f $r.Name, $r.ExpectedPath)
            & git clone --quiet --branch $r.Branch $r.Url $r.ExpectedPath
            if ($LASTEXITCODE -ne 0) {
                # La branche du manifeste peut ne pas exister sur ce depot : on
                # clone quand meme, le verdict BRANCHE_KO le dira ensuite.
                & git clone --quiet $r.Url $r.ExpectedPath
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Output ("{0,-28} CLONE OK         {1}" -f $r.Name, $r.ExpectedPath)
            }
            else {
                $problems++
                Write-Output ("{0,-28} CLONE ECHOUE     verifier le VPN et les droits GitLab sur {1}" -f $r.Name, $r.Url)
            }
        }
    }

    'update' {
        foreach ($r in $repos) {
            if (-not $r.Present) {
                Write-Output ("{0,-28} ABSENT           rien a mettre a jour, voir -Action ensure" -f $r.Name)
                continue
            }
            if (-not $r.Managed) {
                Write-Output ("{0,-28} GERE PAR VOUS    non touche : rafraichir vous-meme, git -C {1} pull --ff-only" -f $r.Name, $r.Path)
                continue
            }

            $f = Invoke-Git @('-C', $r.Path, 'fetch', '--quiet', '--prune')
            if (-not $f.Ok) {
                $problems++
                Write-Output ("{0,-28} FETCH ECHOUE     verifier le VPN et les droits GitLab" -f $r.Name)
                continue
            }

            $dirty = (Invoke-Git @('-C', $r.Path, 'status', '--porcelain')).Out
            if ($dirty) {
                $problems++
                Write-Output ("{0,-28} SALE             non touche : working tree non vide sur un clone gere, anormal" -f $r.Name)
                continue
            }

            $ref = Get-PdpTargetRef -Repo $r
            $behind = (Invoke-Git @('-C', $r.Path, 'rev-list', '--count', "HEAD..$ref")).Out
            if ($behind -eq '0') {
                Write-Output ("{0,-28} DEJA A JOUR      {1}" -f $r.Name, $r.Path)
                continue
            }

            $p = Invoke-Git @('-C', $r.Path, 'pull', '--ff-only', '--quiet')
            if ($p.Ok) {
                Write-Output ("{0,-28} MIS A JOUR       {1} commit(s) recupere(s)" -f $r.Name, $behind)
            }
            else {
                $problems++
                Write-Output ("{0,-28} PULL ECHOUE      fast-forward impossible, intervention manuelle necessaire sur {1}" -f $r.Name, $r.Path)
            }
        }
    }

    'zones' {
        foreach ($r in $repos) {
            if (-not $r.Present) {
                $problems++
                Write-Output ("checkout {0} ({1}) ABSENT : attendu dans {2}" -f $r.Name, $r.Project, $r.ExpectedPath)
                continue
            }
            $res = Test-PdpFreshness -Repo $r -NoFetch:$NoFetch
            $sha = if ($res.Sha) { $res.Sha } else { 'inconnu' }
            $ref = if ($res.Ref) { $res.Ref } else { "origin/$($r.Branch)" }
            if ($res.Verdict -eq 'FETCH_KO' -or $res.Verdict -eq 'BRANCHE_KO') { $problems++ }
            Write-Output ("checkout {0} ({1})" -f $r.Name, $r.Project)
            Write-Output ("    path   {0}" -f $r.Path)
            Write-Output ("    ref    {0}" -f $ref)
            Write-Output ("    sha    {0}" -f $sha)
            Write-Output ("    etat   {0}" -f $res.Verdict)
            foreach ($z in $r.Zones) {
                Write-Output ("    zone   {0}" -f $z)
            }
        }
        if ($problems -gt 0) {
            Write-Output ''
            Write-Output "ATTENTION : $problems checkout(s) sans reference distante exploitable. Le savoir produit pour ceux-la serait invente : les exclure du run et le dire."
        }
    }
}

if ($problems -gt 0) { exit 1 }
exit 0
