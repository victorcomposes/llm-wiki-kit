# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with native backslash paths.
# PreToolUse hook - the council step before a hard-to-reverse edit.
# An Edit/Write to a MIGRATION or CONTRACT path under {{ROOT_DIR}}\<Service>\ is denied until an
# active ticket carries tickets\<id>\council.md (written by /council). The fork gets judged
# by three fresh-context seats before the edit, not explained after it.
#
# Gated paths (case-insensitive, any segment): \Migrations\, \Contracts\, \DTOs\, \Dto\,
# or a filename ending in DTO.cs / Dto.cs / Contract.cs / Event.cs.
# Never gated: files under .vault or any dotfolder, files directly under {{ROOT_DIR}},
# non-code files (only .cs .ts .sql .json are checked).
# Bypass for a fork the user has already ruled on: %TEMP%\claude-council-off-<session_id>.txt
# ponytail: fail-open on any error, same as epcc-gate.ps1. one council.md in any active ticket
# opens the gate for every gated path; per-file tracking if that proves too coarse.

$raw = [Console]::In.ReadToEnd()
try { $o = $raw | ConvertFrom-Json } catch { exit 0 }

if ($o.tool_name -notin @('Edit', 'Write', 'MultiEdit')) { exit 0 }

$fp = $o.tool_input.file_path
if (-not $fp) { exit 0 }

$norm = $fp -replace '/', '\'
if ($norm -notlike '{{ROOT_DIR}}\*') { exit 0 }
$rest = $norm.Substring('{{ROOT_DIR}}\'.Length)
$parts = $rest -split '\\'
if ($parts.Count -lt 2) { exit 0 }
if ([string]::IsNullOrWhiteSpace($parts[0]) -or $parts[0] -like '.*') { exit 0 }

if ($norm -notmatch '\.(cs|ts|sql|json)$') { exit 0 }
$gated = ($norm -match '(?i)\\(Migrations|Contracts|DTOs|Dto)\\') -or
         ($norm -match '(?i)(DTO|Dto|Contract|Event)\.cs$')
if (-not $gated) { exit 0 }

$sid = if ($o.session_id) { $o.session_id } else { 'nosession' }
$bypass = Join-Path $env:TEMP "claude-council-off-$sid.txt"
if (Test-Path $bypass) { exit 0 }

$judged = $false
try {
  $states = Get-ChildItem -Path '{{VAULT_DIR}}\tickets' -Filter 'state.md' -Recurse -Depth 1 -ErrorAction Stop
  foreach ($s in $states) {
    $txt = Get-Content -Path $s.FullName -Raw -ErrorAction Stop
    if ($txt -match '(?m)^status:\s*(active|implemented-pending-review)\s*(#.*)?$') {
      if (Test-Path (Join-Path $s.DirectoryName 'council.md')) { $judged = $true; break }
    }
  }
} catch { exit 0 }

if ($judged) { exit 0 }

$marker = Join-Path $env:TEMP "claude-council-off-$sid.txt"
$reason = "Council gate: '$norm' is a migration or contract path, which is hard to reverse after deploy, " +
  "and no active ticket has a tickets\<id>\council.md. Do NOT edit yet. Run /council on the fork this edit " +
  "resolves (edit in place vs new migration, shape A vs shape B, and so on): three fresh-context seats judge it, " +
  "the decision lands in council.md with its dissent, the user rules, then re-issue the edit. " +
  "User has already ruled on this fork? Ask them to confirm, then create $marker to bypass for this session."

@{ hookSpecificOutput = @{
    hookEventName            = 'PreToolUse'
    permissionDecision       = 'deny'
    permissionDecisionReason = $reason
} } | ConvertTo-Json -Compress
exit 0
