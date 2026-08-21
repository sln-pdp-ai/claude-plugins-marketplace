<#
.SYNOPSIS
    Hook PreToolUse : bloque les ecritures interdites par la doctrine du workbench.

.DESCRIPTION
    Les regles permissions.deny d'un settings.json ne voyagent pas dans un plugin.
    Ce hook les reconstitue : le code de retour 2 bloque l'appel d'outil sans
    condition, et le message de stderr est rendu au modele.

    Trois modes :
      -Mode atlassian : bloque les outils d'ecriture Jira et Confluence. Le
                        workbench produit du Markdown a coller, jamais une
                        ecriture directe dans un ticket ou une page.
      -Mode files     : bloque une ecriture visant un checkout de code que le
                        plugin resout comme source en lecture seule.
      -Mode git       : bloque une commande git mutante visant un checkout.
                        Sans ce mode, le mode files ne servirait a rien : un
                        git checkout ou un git reset dans un depot d'equipe fait
                        les degats que l'interdiction d'ecrire cherche a eviter.

    Ce que le mode files ne bloque PAS, volontairement : les ecritures dans le
    projet courant de l'utilisateur. Le PO ecrit ses stories, ses studies et son
    knowledge/ chez lui. Le hook protege les depots des equipes de dev, pas le
    poste de travail de la personne.
#>
[CmdletBinding()]
param(
    [ValidateSet('files', 'atlassian', 'git')][string]$Mode = 'files'
)

. (Join-Path $PSScriptRoot 'pdp-lib.ps1')

$hook = Read-PdpHookInput

if ($Mode -eq 'atlassian') {
    if ($env:PDP_ALLOW_ATLASSIAN_WRITES -eq '1') { exit 0 }
    $tool = if ($hook -and $hook.PSObject.Properties['tool_name']) { $hook.tool_name } else { 'un outil d ecriture Atlassian' }
    [Console]::Error.WriteLine("Bloque par le plugin pdp-po-workbench : $tool ecrit dans Jira ou Confluence. Ce plugin produit des livrables Markdown relus et versionnes, que la personne colle elle-meme dans le ticket ou la page. Ecrire le fichier, puis rendre son chemin. (Echappatoire assumee : PDP_ALLOW_ATLASSIAN_WRITES=1.)")
    exit 2
}

$cwd = if ($hook -and $hook.PSObject.Properties['cwd']) { $hook.cwd } else { (Get-Location).Path }

if ($Mode -eq 'git') {
    $cmd = $null
    if ($hook -and $hook.PSObject.Properties['tool_input'] -and $hook.tool_input.PSObject.Properties['command']) {
        $cmd = $hook.tool_input.command
    }
    if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

    # Verbes qui modifient un working tree, un index ou une ref locale, ancres
    # juste apres git pour ne pas se declencher sur un argument. Les lectures
    # (fetch, log, show, diff, rev-parse, ls-tree, status, blame) ne sont pas dans
    # la liste : la synchro en a besoin. Volontairement absents aussi : prune et
    # gc, que 'git fetch --prune' ferait matcher a tort.
    $mutating = 'add|am|apply|branch|checkout|cherry-pick|clean|commit|merge|mv|pull|push|rebase|reset|restore|revert|rm|stash|switch|tag|update-ref|worktree'
    if ($cmd -notmatch "\bgit\s+(?:-C\s+\S+\s+|-c\s+\S+\s+)*($mutating)\b") { exit 0 }

    foreach ($r in (Resolve-PdpCheckouts -Project 'all' -Cwd $cwd)) {
        if (-not $r.Present) { continue }
        if ($r.IsProjectRoot) { continue }
        # Le chemin apparait-il dans la commande, sous forme absolue ou relative ?
        $leaf = Split-Path -Leaf $r.Path
        $hitsPath = $cmd.IndexOf($r.Path, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        $hitsLeaf = $cmd -match ("(^|[\s""'/\\])" + [regex]::Escape($leaf) + "([\s""'/\\]|$)")
        if ($hitsPath -or $hitsLeaf) {
            [Console]::Error.WriteLine("Bloque par le plugin pdp-po-workbench : cette commande git modifierait $($r.Name), un depot d'equipe que ce plugin lit en source et ne touche jamais. Seul pdp-repos.ps1 -Action update a le droit de rafraichir un clone de travail, en fast-forward. Pour lire, utiliser git fetch / log / show / diff.")
            exit 2
        }
    }
    exit 0
}

# Mode files : la cible de l'ecriture est-elle dans un checkout en lecture seule ?
$target = $null
if ($hook -and $hook.PSObject.Properties['tool_input']) {
    foreach ($p in @('file_path', 'path', 'notebook_path')) {
        if ($hook.tool_input.PSObject.Properties[$p]) { $target = $hook.tool_input.$p; break }
    }
}
if ([string]::IsNullOrWhiteSpace($target)) { exit 0 }

try { $target = [System.IO.Path]::GetFullPath($target) } catch { exit 0 }

foreach ($r in (Resolve-PdpCheckouts -Project 'all' -Cwd $cwd)) {
    if (-not $r.Present) { continue }
    if ($r.IsProjectRoot) { continue }
    if ($target.StartsWith($r.Path, [System.StringComparison]::OrdinalIgnoreCase)) {
        [Console]::Error.WriteLine("Bloque par le plugin pdp-po-workbench : $target est dans $($r.Name), un depot d'equipe que ce plugin lit en source pour ancrer les livrables, et ne modifie jamais. Une correction de code se rend en proposition dans la story, elle s'applique par l'equipe qui en est proprietaire.")
        exit 2
    }
}

exit 0
