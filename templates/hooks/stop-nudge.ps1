# Stop hook for every {{ROOT_DIR}} session — Windows variant, referenced from
# ~/.claude/settings.json. Two duties, one hook (so only one Stop hook ever runs):
#   1. If a service repo was touched this session (breadcrumb from
#      capture-nudge.ps1) and we haven't nagged yet, block ONCE with the
#      capture reminder. A .nagged marker prevents re-blocking every turn;
#      the breadcrumb itself is left for /capture to consume.
#   2. Otherwise, if the vault has uncommitted changes, show a bookkeeping
#      nudge (log.md / index.md / commit). Silent when the tree is clean.

$raw = [Console]::In.ReadToEnd()
try { $o = $raw | ConvertFrom-Json } catch { exit 0 }
if ($o.stop_hook_active) { exit 0 }
if ($o.cwd -notlike '{{ROOT_DIR}}*') { exit 0 }

$sid    = if ($o.session_id) { $o.session_id } else { 'nosession' }
$crumb  = Join-Path $env:TEMP "claude-svc-$sid.txt"
$nagged = Join-Path $env:TEMP "claude-svc-$sid.nagged"

if ((Test-Path $crumb) -and -not (Test-Path $nagged)) {
    New-Item -ItemType File -Path $nagged -Force | Out-Null
    @{
        decision = 'block'
        reason   = 'Before ending this session: per the root schema''s capture standing rule, check whether you learned anything substantive about a service this session (how a subsystem works, a non-obvious code path, an architectural constraint, a cross-service relationship, a gotcha or failure mode). If so, file it into that service''s folder-note at {{VAULT_DIR}}/wiki/services/<Name>/<Name>.md before stopping - not only in the ticket. If nothing substantive came up, or it is already filed, briefly say so and stop.'
    } | ConvertTo-Json -Compress
    exit 0
}

$dirty = @(git -C '{{VAULT_DIR}}' status --porcelain 2>$null).Count
if ($dirty -gt 0) {
    @{ systemMessage = "Vault bookkeeping: $dirty uncommitted change(s) -- file knowledge to folder-notes, update log.md/index.md, and commit before wrapping up." } | ConvertTo-Json -Compress
}
exit 0
