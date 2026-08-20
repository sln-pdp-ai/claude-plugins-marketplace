<#
.SYNOPSIS
    Brique commune aux plugins SMT : resolution des depots, fraicheur, garde-fous.

.DESCRIPTION
    Ce fichier est dot-source par smt-repos.ps1, smt-session-start.ps1 et
    smt-deny-write.ps1. Il ne fait rien tout seul.

    Copie synchronisee : le meme fichier existe dans chaque plugin
    (plugins/*/bin/smt-lib.ps1). Un plugin installe est copie dans un cache et ne
    peut pas lire de fichier hors de son propre dossier, donc pas de dossier
    partage possible. Toute correction ici doit etre reportee dans l'autre plugin.

    Messages volontairement sans accents : Windows PowerShell 5.1 lit un .ps1 sans
    BOM avec la page de codes ANSI, ce qui rendrait les accents illisibles.
#>

Set-StrictMode -Version 2.0

$script:SmtRepoDefs = @(
    @{
        Key    = 'spec'
        Name   = 'sln-smt-spec-owner'
        Kind   = 'spec'
        EnvVar = 'SMT_SPEC_DIR'
        Url    = 'https://gitlab.amersports.com/pdp/smt/sln-smt-spec-owner.git'
        Marker = 'solution-overview/glossary.md'
        Role   = 'specs et glossaire (source de verite)'
    },
    @{
        Key    = 'backend'
        Name   = 'sln-smt-backend'
        Kind   = 'code'
        EnvVar = 'SMT_BACKEND_DIR'
        Url    = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-smt-backend.git'
        Marker = ''
        Role   = 'code du service backend'
    },
    @{
        Key    = 'console'
        Name   = 'sln-smt-console'
        Kind   = 'code'
        EnvVar = 'SMT_CONSOLE_DIR'
        Url    = 'https://gitlab.amersports.com/core-soa/consoles/salomon-product/sln-smt-console.git'
        Marker = ''
        Role   = 'code de la console (UI)'
    }
)

function Get-SmtRepoDefs {
    param([ValidateSet('spec', 'code', 'all')][string]$Need = 'all')
    switch ($Need) {
        'spec' { $script:SmtRepoDefs | Where-Object { $_.Kind -eq 'spec' } }
        'code' { $script:SmtRepoDefs | Where-Object { $_.Kind -eq 'code' } }
        default { $script:SmtRepoDefs }
    }
}

function Invoke-Git {
    # Encapsule un appel git : rend la sortie propre, sans faire echouer le script.
    param([string[]]$Arguments)
    $out = & git @Arguments 2>$null
    return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Out = ($out | Out-String).Trim() }
}

function Test-IsGitRepo {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path '.git'))
}

function Test-SmtMarker {
    # Un depot n'est reconnu que s'il porte sa marque. Un dossier vide qui porte le
    # bon nom n'est pas le depot : le confondre ferait repondre sur du vide.
    param([hashtable]$Def, [string]$Path)
    if (-not (Test-IsGitRepo -Path $Path)) { return $false }
    if ([string]::IsNullOrEmpty($Def.Marker)) {
        $r = Invoke-Git @('-C', $Path, 'remote', 'get-url', 'origin')
        if ($r.Ok -and $r.Out -like "*$($Def.Name)*") { return $true }
        return ((Split-Path -Leaf $Path) -eq $Def.Name)
    }
    return (Test-Path -LiteralPath (Join-Path $Path $Def.Marker))
}

function Get-SmtProjectRoot {
    param([string]$Cwd)
    if ([string]::IsNullOrWhiteSpace($Cwd)) { $Cwd = (Get-Location).Path }
    $r = Invoke-Git @('-C', $Cwd, 'rev-parse', '--show-toplevel')
    if ($r.Ok -and $r.Out) { return ($r.Out -replace '/', '\') }
    return $Cwd
}

function Get-SmtCacheRoot {
    <#
        Les clones de travail vont dans un dossier tmp du projet courant, comme
        demande. Condition : que git l'ignore. Sinon on salirait le working tree
        d'un depot qu'on est justement cense ne pas toucher, et le controle de
        fraicheur ("working tree non vide") crierait a chaque fois. Dans ce cas,
        repli sur un cache utilisateur, hors de tout depot.
    #>
    param([string]$Cwd)
    $root = Get-SmtProjectRoot -Cwd $Cwd
    $local = Join-Path $root '.smt-tmp'

    if (-not (Test-IsGitRepo -Path $root)) { return $local }

    $null = & git -C $root check-ignore -q '.smt-tmp' 2>$null
    if ($LASTEXITCODE -eq 0) { return $local }

    if ($env:LOCALAPPDATA) { return (Join-Path $env:LOCALAPPDATA 'smt-assistant\repos') }
    return (Join-Path $HOME '.cache/smt-assistant/repos')
}

function Resolve-SmtRepo {
    <#
        Ordre de resolution, du plus explicite au plus automatique :
          1. variable d'environnement dediee (SMT_SPEC_DIR, ...) ;
          2. le projet courant EST ce depot (cas du spec owner, cas d'un dev dans
             son checkout) ;
          3. repos/<nom> sous le projet courant, si l'utilisateur y a clone les depots ;
          4. depot frere ../<nom> ;
          5. clone de travail dans le dossier tmp (voir Get-SmtCacheRoot).
        Les cas 1 a 4 sont des depots que l'utilisateur gere lui-meme. Le cas 5 est
        une copie geree par le plugin.
    #>
    param([hashtable]$Def, [string]$Cwd)

    $root = Get-SmtProjectRoot -Cwd $Cwd
    $cacheRoot = Get-SmtCacheRoot -Cwd $Cwd
    $cachePath = Join-Path $cacheRoot $Def.Name

    $candidates = @()
    $envPath = [Environment]::GetEnvironmentVariable($Def.EnvVar)
    if ($envPath) { $candidates += @{ Path = $envPath; Origin = "variable $($Def.EnvVar)"; Managed = $false } }
    $candidates += @{ Path = $root; Origin = 'projet courant'; Managed = $false }
    $candidates += @{ Path = (Join-Path $root ('repos\' + $Def.Name)); Origin = 'repos/'; Managed = $false }
    $parent = Split-Path -Parent $root
    if ($parent) { $candidates += @{ Path = (Join-Path $parent $Def.Name); Origin = 'depot frere'; Managed = $false } }
    $candidates += @{ Path = $cachePath; Origin = 'clone de travail (tmp)'; Managed = $true }

    foreach ($c in $candidates) {
        if (Test-SmtMarker -Def $Def -Path $c.Path) {
            return [pscustomobject]@{
                Key = $Def.Key; Name = $Def.Name; Kind = $Def.Kind; Role = $Def.Role
                Url = $Def.Url; Present = $true
                Path = (Resolve-Path -LiteralPath $c.Path).Path
                Origin = $c.Origin; Managed = $c.Managed
                IsProjectRoot = ((Resolve-Path -LiteralPath $c.Path).Path -eq $root)
                ExpectedPath = $cachePath
            }
        }
    }

    return [pscustomobject]@{
        Key = $Def.Key; Name = $Def.Name; Kind = $Def.Kind; Role = $Def.Role
        Url = $Def.Url; Present = $false
        Path = $null; Origin = 'introuvable'; Managed = $true
        IsProjectRoot = $false; ExpectedPath = $cachePath
    }
}

function Resolve-SmtRepos {
    param([ValidateSet('spec', 'code', 'all')][string]$Need = 'all', [string]$Cwd)
    foreach ($def in (Get-SmtRepoDefs -Need $Need)) {
        Resolve-SmtRepo -Def $def -Cwd $Cwd
    }
}

function Get-SmtLastFetch {
    # Date du dernier fetch, sans reseau : mtime de .git/FETCH_HEAD.
    param([string]$Path)
    $f = Join-Path $Path '.git\FETCH_HEAD'
    if (Test-Path -LiteralPath $f) {
        return (Get-Item -LiteralPath $f).LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    }
    return 'jamais'
}

function Test-SmtFreshness {
    <#
        Rend un verdict par depot : A_JOUR, EN_RETARD, FETCH_KO, SALE, ABSENT.
        Aucune mise a jour n'est faite : rafraichir modifie le checkout, ce qui
        sort du perimetre lecture seule.
    #>
    param([pscustomobject]$Repo, [switch]$NoFetch)

    if (-not $Repo.Present) {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'ABSENT'; Detail = "attendu dans $($Repo.ExpectedPath)" }
    }

    if (-not $NoFetch) {
        $f = Invoke-Git @('-C', $Repo.Path, 'fetch', '--quiet')
        if (-not $f.Ok) {
            return [pscustomobject]@{ Repo = $Repo; Verdict = 'FETCH_KO'; Detail = 'fetch impossible (VPN ? identifiants GitLab ?) : fraicheur inverifiable' }
        }
    }

    $branch = (Invoke-Git @('-C', $Repo.Path, 'rev-parse', '--abbrev-ref', 'HEAD')).Out
    $upstream = (Invoke-Git @('-C', $Repo.Path, 'for-each-ref', '--format=%(upstream:short)', "refs/heads/$branch")).Out
    if ([string]::IsNullOrWhiteSpace($upstream)) { $upstream = 'origin/HEAD' }

    $dirty = (Invoke-Git @('-C', $Repo.Path, 'status', '--porcelain')).Out
    if ($dirty -and -not $Repo.IsProjectRoot) {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'SALE'; Detail = "working tree non vide sur $branch : le contenu lu ne correspond plus a ce qui est versionne" }
    }

    $behind = (Invoke-Git @('-C', $Repo.Path, 'rev-list', '--count', "HEAD..$upstream")).Out
    if ($behind -eq '0') {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'A_JOUR'; Detail = "$branch, a jour avec $upstream" }
    }

    $last = (Invoke-Git @('-C', $Repo.Path, 'log', '-1', '--format=%cI', $upstream)).Out
    return [pscustomobject]@{ Repo = $Repo; Verdict = 'EN_RETARD'; Detail = "$behind commit(s) de retard sur $upstream (dernier distant : $last)" }
}

function Format-SmtLine {
    param([pscustomobject]$Result)
    $r = $Result.Repo
    $where = if ($r.Present) { $r.Path } else { $r.ExpectedPath }
    $origin = if ($r.Present) { " [$($r.Origin)]" } else { '' }
    return ("{0,-20} {1,-10} {2}{3} -> {4}" -f $r.Name, $Result.Verdict, $Result.Detail, $origin, $where)
}

function Read-SmtHookInput {
    # Les hooks recoivent leur contexte en JSON sur stdin. Absent hors hook.
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return ($raw | ConvertFrom-Json) } catch { return $null }
}
