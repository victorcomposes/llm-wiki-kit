# PostToolUse hook — nudges the agent to file service knowledge while it's fresh.
# Windows variant. Referenced from ~/.claude/settings.json so it fires in every
# {{ROOT_DIR}} session (settings.json does NOT cascade up the directory tree —
# a vault-level hook would only fire in vault sessions).
# Fires after a file under {{ROOT_DIR}}\<Service>\ is modified. Once per service
# per session (breadcrumb file in TEMP), so it never spams during multi-file edits.
# The same breadcrumb is consumed by /capture and by stop-nudge.ps1.

$raw = [Console]::In.ReadToEnd()
try { $o = $raw | ConvertFrom-Json } catch { exit 0 }

# Only care about file-modifying tools.
if ($o.tool_name -notin @('Edit', 'Write', 'MultiEdit')) { exit 0 }

$fp = $o.tool_input.file_path
if (-not $fp) { exit 0 }

# Normalise slashes; must live under the root dir.
$norm = $fp -replace '/', '\'
if ($norm -notlike '{{ROOT_DIR}}\*') { exit 0 }

# First path segment under the root is the service repo dir.
$rest = $norm.Substring('{{ROOT_DIR}}\'.Length)
$parts = $rest -split '\\'
# A file directly under the root (e.g. CLAUDE.md) is not a service repo.
if ($parts.Count -lt 2) { exit 0 }
$seg = $parts[0]
if ([string]::IsNullOrWhiteSpace($seg)) { exit 0 }

# Skip the vault itself and any dotfolder (.vault, .claude, .git, ...).
if ($seg -like '.*') { exit 0 }

# Breadcrumb: one service per line, keyed by session. Dedup => once per service.
$sid = if ($o.session_id) { $o.session_id } else { 'nosession' }
$crumb = Join-Path $env:TEMP "claude-svc-$sid.txt"
$seen = @()
if (Test-Path $crumb) { $seen = @(Get-Content $crumb) }
if ($seen -contains $seg) { exit 0 }
Add-Content -Path $crumb -Value $seg

$msg = "You just modified a file in the '$seg' service repo ($fp). " +
"Per the root schema's capture standing rule, when you reach a natural stopping point in this change, " +
"run /capture to file any substantive knowledge you gained about '$seg' " +
"(how a subsystem works, a non-obvious code path, an architectural constraint, a cross-service " +
"relationship, a gotcha or failure mode) into its folder-note under " +
"{{VAULT_DIR}}/wiki/services/ - pick the precise nested folder-note matching the path. " +
"If nothing substantive came up, no action needed. This nudge fires once per service per session."

$out = @{
    hookSpecificOutput = @{
        hookEventName    = 'PostToolUse'
        additionalContext = $msg
    }
}
$out | ConvertTo-Json -Compress
exit 0
