<#
.SYNOPSIS
    Hook PreToolUse : bloque les ecritures interdites par la doctrine SMT.

.DESCRIPTION
    Les regles permissions.deny d'un settings.json ne voyagent pas dans un plugin.
    Ce hook les reconstitue : le code de retour 2 bloque l'appel d'outil sans
    condition, et le message de stderr est rendu au modele.

    Deux modes :
      -Mode atlassian : bloque les outils d'ecriture Jira et Confluence.
      -Mode files     : bloque une ecriture visant un depot SMT que le plugin gere
                        comme source en lecture seule.

    Ce que le mode files ne bloque PAS, volontairement : les ecritures dans le
    projet courant de l'utilisateur. Le spec owner doit pouvoir rediger ses specs
    dans son propre depot, et un dev doit pouvoir ecrire son code dans le sien. Le
    hook protege les copies que le plugin resout comme sources externes, pas le
    poste de travail de la personne.

    Copie synchronisee entre les plugins SMT : voir l'en-tete de smt-lib.ps1.
#>
[CmdletBinding()]
param(
    [ValidateSet('files', 'atlassian')][string]$Mode = 'files',
    [ValidateSet('spec', 'code', 'all')][string]$Need = 'spec'
)

. (Join-Path $PSScriptRoot 'smt-lib.ps1')

$hook = Read-SmtHookInput

if ($Mode -eq 'atlassian') {
    if ($env:SMT_ALLOW_ATLASSIAN_WRITES -eq '1') { exit 0 }
    $tool = if ($hook -and $hook.PSObject.Properties['tool_name']) { $hook.tool_name } else { 'un outil d ecriture Atlassian' }
    [Console]::Error.WriteLine("Bloque par le plugin SMT : $tool ecrit dans Jira ou Confluence, or l'assistant SMT est en lecture seule sur les deux. Jira n'est jamais ecrit ; la livraison Confluence appartient au projet du spec owner. Restituer le resultat en proposition dans le chat. (Echappatoire assumee : SMT_ALLOW_ATLASSIAN_WRITES=1.)")
    exit 2
}

# Mode files : la cible de l'ecriture est-elle dans un depot SMT en lecture seule ?
$target = $null
if ($hook -and $hook.PSObject.Properties['tool_input']) {
    foreach ($p in @('file_path', 'path', 'notebook_path')) {
        if ($hook.tool_input.PSObject.Properties[$p]) { $target = $hook.tool_input.$p; break }
    }
}
if ([string]::IsNullOrWhiteSpace($target)) { exit 0 }

try { $target = [System.IO.Path]::GetFullPath($target) } catch { exit 0 }

$cwd = if ($hook -and $hook.PSObject.Properties['cwd']) { $hook.cwd } else { (Get-Location).Path }

foreach ($r in (Resolve-SmtRepos -Need $Need -Cwd $cwd)) {
    if (-not $r.Present) { continue }
    if ($r.IsProjectRoot) { continue }
    if ($target.StartsWith($r.Path, [System.StringComparison]::OrdinalIgnoreCase)) {
        [Console]::Error.WriteLine("Bloque par le plugin SMT : $target est dans $($r.Name), que ce plugin lit en source ($($r.Role)) et ne modifie jamais. Une correction de spec ou de code se rend en proposition, elle s'applique par la personne qui en est proprietaire.")
        exit 2
    }
}

exit 0
