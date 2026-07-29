<#
.SYNOPSIS
    Prepare un poste pour l'assistant SMT (Claude Code hors VSCode).

.DESCRIPTION
    Verifie les prerequis, clone les deux depots SMT dans repos/ s'ils sont absents,
    et controle la fraicheur de ceux qui sont deja la.

    Strictement lecture seule vis-a-vis de GitLab : clone et fetch uniquement.
    Un clone existant n'est mis a jour que si -Update est passe explicitement.

    Note : les messages de ce script sont volontairement sans accents. Windows
    PowerShell 5.1 lit un .ps1 sans BOM avec la page de codes ANSI, ce qui
    transformerait des accents UTF-8 en caracteres illisibles.

.PARAMETER Update
    Met a jour les clones existants deja en retard (git pull --ff-only).
    Sans ce commutateur, le script se contente de signaler le retard.

.EXAMPLE
    .\scripts\bootstrap.ps1
    Provisionne ce qui manque et fait un etat des lieux.

.EXAMPLE
    .\scripts\bootstrap.ps1 -Update
    Idem, et rafraichit les clones en retard.
#>
[CmdletBinding()]
param(
    [switch]$Update
)

$ErrorActionPreference = 'Stop'

$Repos = @(
    @{
        Name = 'sln-smt-backend'
        Url  = 'https://gitlab.amersports.com/core-soa/services/salomon-product/sln-smt-backend.git'
    },
    @{
        Name = 'sln-smt-console'
        Url  = 'https://gitlab.amersports.com/core-soa/consoles/salomon-product/sln-smt-console.git'
    }
)

function Write-Step { param([string]$Text) Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Text) Write-Host "    OK   $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text) Write-Host "    ATTN $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host "    KO   $Text" -ForegroundColor Red }
function Write-Info { param([string]$Text) Write-Host "         $Text" -ForegroundColor DarkGray }

$Problems = 0

# --- Prerequis ---------------------------------------------------------------

Write-Step 'Prerequis'

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitCmd) {
    Write-Fail 'git est introuvable.'
    Write-Info 'Installer Git for Windows : https://git-scm.com/download/win'
    Write-Info 'Puis relancer ce script dans une nouvelle fenetre.'
    exit 1
}
Write-Ok "git present : $($gitCmd.Source)"

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root 'CLAUDE.md'))) {
    Write-Fail "Racine du projet introuvable (CLAUDE.md absent de $root)."
    Write-Info 'Lancer ce script depuis le depot sln-smt-assistant.'
    exit 1
}
Write-Ok "Projet : $root"

$reposDir = Join-Path $root 'repos'
if (-not (Test-Path $reposDir)) {
    New-Item -ItemType Directory -Path $reposDir | Out-Null
    Write-Ok 'Dossier repos/ cree'
}

# --- Depots ------------------------------------------------------------------

foreach ($repo in $Repos) {
    $name = $repo.Name
    $url  = $repo.Url
    $path = Join-Path $reposDir $name

    Write-Step $name

    if (-not (Test-Path (Join-Path $path '.git'))) {
        Write-Info 'Absent : clone en cours (peut demander vos identifiants GitLab)...'
        git clone --quiet $url $path
        if ($LASTEXITCODE -ne 0) {
            Write-Fail 'Clone echoue.'
            Write-Info 'Verifier le VPN et les identifiants GitLab (memes que les autres depots sln-*).'
            $Problems++
            continue
        }
        Write-Ok 'Clone termine'
    }

    git -C $path fetch --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'fetch impossible : fraicheur inverifiable, donc code non fiable.'
        Write-Info 'Verifier le VPN et les identifiants GitLab, puis relancer.'
        $Problems++
        continue
    }

    $branch = (git -C $path rev-parse --abbrev-ref HEAD).Trim()

    # for-each-ref plutot que rev-parse '@{u}' : rend une chaine vide au lieu
    # d'ecrire sur stderr quand la branche n'a pas d'upstream (ou HEAD detachee).
    $upstream = (git -C $path for-each-ref --format='%(upstream:short)' "refs/heads/$branch")
    if ([string]::IsNullOrWhiteSpace($upstream)) {
        $upstream = 'origin/HEAD'
        Write-Warn "Pas d'upstream sur '$branch' : repli sur origin/HEAD."
    }
    else {
        $upstream = $upstream.Trim()
    }

    $behind = (git -C $path rev-list --count "HEAD..$upstream").Trim()
    $dirty  = git -C $path status --porcelain

    if ($dirty) {
        Write-Warn 'Working tree non vide : le code lu ne correspond plus a ce qui est versionne.'
        Write-Info 'Les depots sous repos/ doivent rester intacts (perimetre lecture seule).'
        $Problems++
    }

    if ($behind -eq '0') {
        Write-Ok "A jour sur $branch (suit $upstream)"
    }
    else {
        $lastRemote = (git -C $path log -1 --format='%cI' $upstream).Trim()
        Write-Warn "En retard de $behind commit(s) sur $upstream (dernier distant : $lastRemote)"
        if ($Update -and -not $dirty) {
            git -C $path pull --ff-only --quiet
            if ($LASTEXITCODE -eq 0) { Write-Ok 'Mis a jour' }
            else { Write-Fail 'Mise a jour echouee (avance divergente ?).'; $Problems++ }
        }
        elseif ($Update -and $dirty) {
            Write-Fail 'Mise a jour refusee : working tree non vide.'
            $Problems++
        }
        else {
            Write-Info "Pour rafraichir : git -C repos/$name pull --ff-only"
            Write-Info 'Ou relancer ce script avec -Update.'
            $Problems++
        }
    }
}

# --- Etapes manuelles --------------------------------------------------------

Write-Step 'Reste a faire a la main'
Write-Info '1. Ouvrir ce dossier dans Claude Code et approuver le serveur MCP du projet.'
Write-Info '2. Taper /mcp, choisir atlassian, et s authentifier dans le navigateur (OAuth).'
Write-Info '3. Verifier avec : /spec-readiness SMT'

Write-Step 'Bilan'
if ($Problems -eq 0) {
    Write-Ok 'Poste pret : depots presents, a jour et intacts.'
    exit 0
}
Write-Warn "$Problems point(s) a traiter avant d'utiliser les skills de comparaison de code."
Write-Info 'Ces skills refusent de conclure sur un clone absent, perime ou modifie.'
exit 1
