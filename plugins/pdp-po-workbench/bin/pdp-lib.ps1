<#
.SYNOPSIS
    Brique commune du plugin pdp-po-workbench : manifeste des projets, resolution
    des checkouts, fraicheur, garde-fous.

.DESCRIPTION
    Ce fichier est dot-source par pdp-repos.ps1, pdp-session-start.ps1 et
    pdp-deny-write.ps1. Il ne fait rien tout seul.

    Il porte la donnee OPERATIONNELLE du domaine PDP : quel projet est adosse a
    quels depots git, sur quelle branche, et quelles zones de fichiers valent la
    peine d'etre lues. Cette donnee vit ici et pas dans pdp-architecture : un
    plugin installe ne peut rien lire hors de son propre dossier, et
    pdp-architecture porte la carte editoriale des applications, pas l'annuaire
    des URLs git.

    Ce qu'il ne porte PAS : l'etat de synchronisation. Le SHA du dernier commit
    ingere par projet vit chez l'utilisateur, dans knowledge/core/sync-state.md,
    a cote du savoir qu'il decrit. Un plugin installe est une copie en cache,
    ecrasee a chaque mise a jour : y ecrire un etat le perdrait en silence.

    Messages volontairement sans accents : Windows PowerShell 5.1 lit un .ps1 sans
    BOM avec la page de codes ANSI, ce qui rendrait les accents illisibles.
#>

Set-StrictMode -Version 2.0

# Zones par defaut : la forme d'un microservice Serverless v3 du domaine. Un
# projet qui range son code autrement surcharge la cle Zones.
$script:PdpDefaultZones = @(
    'serverless.yml', 'serverless.ts',
    'src/handlers/**/*.ts', 'src/handlers/**/*.js',
    'src/functions/**/*.ts', 'src/functions/**/*.js',
    'src/services/**/*.ts', 'src/services/**/*.js',
    'src/schemas/**/*.json', 'schemas/**/*.json',
    'package.json', 'README.md'
)

$script:PdpProjects = @(
    @{
        Slug      = 'new-pim-salsify'
        Label     = 'PIM Salsify : connecteurs entrant et sortant'
        Branch    = 'quality'
        Knowledge = @('architecture.md', 'connectors-map.md', 'implementation-memory.md')
        Checkouts = @(
            @{ Name = 'sln-salsify-in-connector'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-salsify-in-connector.git' },
            @{ Name = 'sln-salsify-out-connector'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-salsify-out-connector.git' }
        )
    },
    @{
        Slug      = 'new-dam-aprimo'
        Label     = 'DAM Aprimo : connecteurs assets'
        Branch    = 'quality'
        Knowledge = @('architecture.md', 'connectors-map.md', 'implementation-memory.md')
        Checkouts = @(
            @{ Name = 'sln-aprimo-connector'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-aprimo-connector.git' },
            @{ Name = 'as-aprimo-lconnector'; Url = 'https://gitlab.amersports.com/core-soa/services/pdp/as-aprimo-lconnector.git' }
        )
    },
    @{
        Slug      = 'triple-a'
        Label     = 'Triple A : affectation automatique des assets'
        Branch    = 'quality'
        Knowledge = @('project.md', 'architecture.md', 'implementation-memory.md')
        Checkouts = @(
            @{ Name = 'sln-asset-auto-assign'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-asset-auto-assign.git' }
        )
    },
    @{
        Slug      = 'new-aprify'
        Label     = 'Aprify : synchronisation Aprimo vers Salsify'
        Branch    = 'quality'
        Knowledge = @('project.md', 'architecture.md', 'implementation-memory.md')
        Zones     = @(
            'serverless.yml', 'serverless.ts', 'package.json', 'README.md',
            'src/functions/**/*.ts', 'src/functions/**/*.js',
            'src/v1/functions/**/*.ts', 'src/v1/connectors/**/*.ts', 'src/v1/services/**/*.ts',
            'src/v1/clients/**/*.ts', 'src/v1/mappers/**/*.ts', 'src/v1/repositories/**/*.ts',
            'src/v1/models/**/*.ts', 'src/v1/enums/**/*.ts', 'src/v1/configuration/**/*.ts',
            'models/**/*.json'
        )
        Checkouts = @(
            @{ Name = 'sln-aprimo-salsify-sync'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-aprimo-salsify-sync.git' }
        )
    },
    @{
        Slug      = 'merch-aggregator'
        Label     = 'Merch Aggregator : backends D2C et B2B, console'
        Branch    = 'quality'
        Knowledge = @('project.md', 'backend-v1-d2c.md', 'backend-v2-b2b.md', 'frontend-console.md', 'implementation-memory.md')
        Zones     = @(
            'serverless.yml', 'serverless.ts', 'package.json', 'README.md',
            'src/handlers/**/*.ts', 'src/functions/**/*.ts', 'src/services/**/*.ts',
            'src/schemas/**/*.json', 'schemas/**/*.json',
            'src/pages/**/*.tsx', 'src/pages/**/*.ts', 'src/components/**/*.tsx',
            'next.config.js', 'next.config.mjs', 'next.config.ts'
        )
        Checkouts = @(
            @{ Name = 'sln-merchagg'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-merchagg.git' },
            @{ Name = 'sln-merchagg-console'; Url = 'https://gitlab.amersports.com/core-soa/consoles/salomon-product/sln-merchagg-console.git' },
            @{ Name = 'sln-merchaggregator'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-merchaggregator.git' }
        )
    },
    @{
        Slug      = 'bus-bridge-tempo-plm-pmd'
        Label     = 'Bus bridge Tempo PLM / PMD'
        Branch    = 'quality'
        Knowledge = @('project.md', 'architecture.md', 'implementation-memory.md')
        Checkouts = @(
            @{ Name = 'sln-bus-bridge-tempo-plm-pmd'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-bus-bridge-tempo-plm-pmd.git' }
        )
    },
    @{
        Slug      = 'bus-bridge-pdp'
        Label     = 'Bus bridge PDP'
        Branch    = 'quality'
        Knowledge = @('project.md', 'architecture.md', 'implementation-memory.md')
        Zones     = @(
            'serverless.yml', 'serverless.ts', 'package.json', 'README.md',
            'src/v1/functions/**/*.ts', 'src/v1/services/**/*.ts', 'src/v1/authorizers/**/*.ts',
            'models/**/*.json'
        )
        Checkouts = @(
            @{ Name = 'sln-bus-bridge-pdp'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-bus-bridge-pdp.git' }
        )
    },
    @{
        Slug      = 'atma-connector'
        Label     = 'Atma connector : tracabilite'
        Branch    = 'quality'
        Knowledge = @('project.md', 'architecture.md', 'implementation-memory.md')
        Checkouts = @(
            @{ Name = 'sln-atma-connector'; Url = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-atma-connector.git' }
        )
    }
)

function Get-PdpProjectDefs {
    <#
        Rend les projets demandes. 'all' rend tout le manifeste. Un slug inconnu
        ne rend rien : l'appelant doit le signaler plutot que de repondre sur un
        perimetre vide sans le dire.
    #>
    param([string]$Project = 'all')
    if ([string]::IsNullOrWhiteSpace($Project) -or $Project -eq 'all') { return $script:PdpProjects }
    return @($script:PdpProjects | Where-Object { $_.Slug -eq $Project })
}

function Get-PdpProjectSlugs {
    return @($script:PdpProjects | ForEach-Object { $_.Slug })
}

function Get-PdpZones {
    param([hashtable]$Def)
    if ($Def.ContainsKey('Zones')) { return $Def.Zones }
    return $script:PdpDefaultZones
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

function Test-PdpCheckout {
    # Un depot n'est reconnu que s'il porte le bon origin, ou a defaut le bon nom
    # de dossier. Un dossier vide au bon nom n'est pas le depot : le confondre
    # ferait repondre sur du vide.
    param([hashtable]$Checkout, [string]$Path)
    if (-not (Test-IsGitRepo -Path $Path)) { return $false }
    $r = Invoke-Git @('-C', $Path, 'remote', 'get-url', 'origin')
    if ($r.Ok -and $r.Out -like "*$($Checkout.Name)*") { return $true }
    return ((Split-Path -Leaf $Path) -eq $Checkout.Name)
}

function Get-PdpProjectRoot {
    param([string]$Cwd)
    if ([string]::IsNullOrWhiteSpace($Cwd)) { $Cwd = (Get-Location).Path }
    $r = Invoke-Git @('-C', $Cwd, 'rev-parse', '--show-toplevel')
    if ($r.Ok -and $r.Out) { return ($r.Out -replace '/', '\') }
    return $Cwd
}

function Get-PdpCloneRoot {
    <#
        Les clones de travail vont dans local-repos/ du projet courant, comme
        prevu pour le workbench. Condition : que git l'ignore. Sinon on remplirait
        le working tree du depot de savoir de douze checkouts, et le moindre
        git status deviendrait illisible. Dans ce cas, repli sur un cache
        utilisateur, hors de tout depot.
    #>
    param([string]$Cwd)
    $root = Get-PdpProjectRoot -Cwd $Cwd
    $local = Join-Path $root 'local-repos'

    if (-not (Test-IsGitRepo -Path $root)) { return $local }

    $null = & git -C $root check-ignore -q 'local-repos' 2>$null
    if ($LASTEXITCODE -eq 0) { return $local }

    if ($env:LOCALAPPDATA) { return (Join-Path $env:LOCALAPPDATA 'pdp-workbench\repos') }
    return (Join-Path $HOME '.cache/pdp-workbench/repos')
}

function Test-PdpGitignoreAdvice {
    <#
        Signale si ce projet gagnerait a ignorer local-repos, pour que les clones
        restent dans le projet plutot que de partir dans le cache utilisateur
        (voir Get-PdpCloneRoot). Ne s'applique que si le projet courant est
        lui-meme un depot git.
    #>
    param([string]$Cwd)
    $root = Get-PdpProjectRoot -Cwd $Cwd
    if (-not (Test-IsGitRepo -Path $root)) { return $null }
    $null = & git -C $root check-ignore -q 'local-repos' 2>$null
    if ($LASTEXITCODE -eq 0) { return $null }
    return (Join-Path $root '.gitignore')
}

function Resolve-PdpCheckout {
    <#
        Ordre de resolution, du plus explicite au plus automatique :
          1. PDP_REPOS_DIR : un dossier qui contient deja les checkouts ;
          2. le projet courant EST ce depot (cas d'un dev dans son service) ;
          3. depot frere ../<nom> (cas de l'architecte, qui les a cote a cote) ;
          4. clone de travail dans local-repos/ (voir Get-PdpCloneRoot).
        Les cas 1 a 3 sont des depots que l'utilisateur gere lui-meme. Le cas 4
        est une copie geree par le plugin, la seule qu'il ait le droit de
        rafraichir.
    #>
    param([hashtable]$Checkout, [hashtable]$Def, [string]$Cwd)

    $root = Get-PdpProjectRoot -Cwd $Cwd
    $cloneRoot = Get-PdpCloneRoot -Cwd $Cwd
    $clonePath = Join-Path $cloneRoot $Checkout.Name

    $candidates = @()
    $reposDir = [Environment]::GetEnvironmentVariable('PDP_REPOS_DIR')
    if ($reposDir) { $candidates += @{ Path = (Join-Path $reposDir $Checkout.Name); Origin = 'variable PDP_REPOS_DIR'; Managed = $false } }
    $candidates += @{ Path = $root; Origin = 'projet courant'; Managed = $false }
    $parent = Split-Path -Parent $root
    if ($parent) { $candidates += @{ Path = (Join-Path $parent $Checkout.Name); Origin = 'depot frere'; Managed = $false } }
    $candidates += @{ Path = $clonePath; Origin = 'clone de travail (local-repos)'; Managed = $true }

    foreach ($c in $candidates) {
        if (Test-PdpCheckout -Checkout $Checkout -Path $c.Path) {
            $resolved = (Resolve-Path -LiteralPath $c.Path).Path
            return [pscustomobject]@{
                Project = $Def.Slug; Name = $Checkout.Name; Url = $Checkout.Url
                Branch = $Def.Branch; Zones = (Get-PdpZones -Def $Def)
                Present = $true; Path = $resolved
                Origin = $c.Origin; Managed = $c.Managed
                IsProjectRoot = ($resolved -eq $root)
                ExpectedPath = $clonePath
            }
        }
    }

    return [pscustomobject]@{
        Project = $Def.Slug; Name = $Checkout.Name; Url = $Checkout.Url
        Branch = $Def.Branch; Zones = (Get-PdpZones -Def $Def)
        Present = $false; Path = $null
        Origin = 'introuvable'; Managed = $true
        IsProjectRoot = $false; ExpectedPath = $clonePath
    }
}

function Resolve-PdpCheckouts {
    param([string]$Project = 'all', [string]$Cwd)
    foreach ($def in (Get-PdpProjectDefs -Project $Project)) {
        foreach ($co in $def.Checkouts) {
            Resolve-PdpCheckout -Checkout $co -Def $def -Cwd $Cwd
        }
    }
}

function Get-PdpLastFetch {
    # Date du dernier fetch, sans reseau : mtime de .git/FETCH_HEAD.
    param([string]$Path)
    $f = Join-Path $Path '.git\FETCH_HEAD'
    if (Test-Path -LiteralPath $f) {
        return (Get-Item -LiteralPath $f).LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    }
    return 'jamais'
}

function Get-PdpTargetRef {
    <#
        La branche observee est celle du manifeste (quality en general), pas
        celle qui se trouve sortie dans le checkout. Un dev qui travaille sur sa
        feature branch ne doit pas faire deriver le savoir : on lit toujours la
        reference distante de la branche du manifeste.
    #>
    param([pscustomobject]$Repo)
    $ref = "origin/$($Repo.Branch)"
    $r = Invoke-Git @('-C', $Repo.Path, 'rev-parse', '--verify', '--quiet', $ref)
    if ($r.Ok -and $r.Out) { return $ref }
    return 'origin/HEAD'
}

function Test-PdpFreshness {
    <#
        Rend un verdict par checkout : A_JOUR, EN_RETARD, FETCH_KO, BRANCHE_KO,
        ABSENT. Aucune mise a jour n'est faite ici.

        Le working tree sale n'est PAS un verdict bloquant, contrairement aux
        plugins SMT : le savoir est reconstruit depuis la reference distante
        (git show <ref>:<fichier>), pas depuis les fichiers du disque. Un dev qui
        a des modifications en cours peut faire tourner la synchro sans les
        exposer dans le savoir.
    #>
    param([pscustomobject]$Repo, [switch]$NoFetch)

    if (-not $Repo.Present) {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'ABSENT'; Ref = $null; Sha = $null; Detail = "attendu dans $($Repo.ExpectedPath)" }
    }

    if (-not $NoFetch) {
        $f = Invoke-Git @('-C', $Repo.Path, 'fetch', '--quiet', '--prune')
        if (-not $f.Ok) {
            return [pscustomobject]@{ Repo = $Repo; Verdict = 'FETCH_KO'; Ref = $null; Sha = $null; Detail = 'fetch impossible (VPN ? identifiants GitLab ?) : fraicheur inverifiable' }
        }
    }

    $ref = Get-PdpTargetRef -Repo $Repo
    if ($ref -ne "origin/$($Repo.Branch)") {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'BRANCHE_KO'; Ref = $ref; Sha = $null; Detail = "la branche $($Repo.Branch) du manifeste n'existe pas sur origin" }
    }

    $sha = (Invoke-Git @('-C', $Repo.Path, 'rev-parse', $ref)).Out
    $last = (Invoke-Git @('-C', $Repo.Path, 'log', '-1', '--format=%cI', $ref)).Out

    $localRef = (Invoke-Git @('-C', $Repo.Path, 'rev-parse', 'HEAD')).Out
    if ($localRef -eq $sha) {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'A_JOUR'; Ref = $ref; Sha = $sha; Detail = "HEAD est sur $ref (dernier commit distant : $last)" }
    }

    $behind = (Invoke-Git @('-C', $Repo.Path, 'rev-list', '--count', "HEAD..$ref")).Out
    if ($behind -eq '0') {
        return [pscustomobject]@{ Repo = $Repo; Verdict = 'A_JOUR'; Ref = $ref; Sha = $sha; Detail = "$ref est atteignable depuis HEAD (dernier commit distant : $last)" }
    }
    return [pscustomobject]@{ Repo = $Repo; Verdict = 'EN_RETARD'; Ref = $ref; Sha = $sha; Detail = "$behind commit(s) d'avance sur HEAD dans $ref (dernier commit distant : $last)" }
}

function Format-PdpLine {
    param([pscustomobject]$Result)
    $r = $Result.Repo
    $where = if ($r.Present) { $r.Path } else { $r.ExpectedPath }
    $sha = if ($Result.Sha) { " sha=$($Result.Sha.Substring(0, 7))" } else { '' }
    return ("{0,-28} {1,-12} {2,-11}{3} {4} -> {5}" -f $r.Name, $r.Project, $Result.Verdict, $sha, $Result.Detail, $where)
}

function Read-PdpHookInput {
    # Les hooks recoivent leur contexte en JSON sur stdin. Absent hors hook.
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return ($raw | ConvertFrom-Json) } catch { return $null }
}
