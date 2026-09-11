# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with native backslash paths.
# PreToolUse hook - the council step before a hard-to-reverse edit.
# An Edit/Write to a MIGRATION or CONTRACT path under {{ROOT_DIR}}\<Service>\ is denied unless a ruled
# council ledger entry clears it. /council appends entries to tickets\<id>\council.md; an entry
# about a gated edit carries `Clears: <glob>, <glob>` (paths relative to {{ROOT_DIR}}, `*` and `**`).
# A Clears line counts only on an entry whose `Ruling:` line is not pending, and only while the
# ticket's state.md is active or implemented-pending-review. Entries without Clears clear nothing.
#
# Gated paths (case-insensitive, any segment): \Migrations\, \Contracts\, \DTOs\, \Dto\,
# or a filename ending in DTO.cs / Dto.cs / Contract.cs / Event.cs.
# Never gated: files under .vault or any dotfolder, files directly under {{ROOT_DIR}},
# non-code files (only .cs .ts .sql .json are checked).
# Bypass for a fork the user has already ruled on in chat: %TEMP%\claude-council-off-<session_id>.txt
# ponytail: fail-open on any error, same as epcc-gate.ps1. glob match is -like after ** -> *,
# so a glob can only widen, never narrow; good enough until a real miss says otherwise.

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

# Collect Clears globs from ruled entries in every active ticket's ledger.
function Get-RuledClears($ledgerPath) {
  $globs = @()
  try { $lines = Get-Content -Path $ledgerPath -ErrorAction Stop } catch { return $globs }
  $entryClears = @(); $ruled = $false
  foreach ($line in $lines) {
    if ($line -match '^##\s') {
      if ($ruled) { $globs += $entryClears }
      $entryClears = @(); $ruled = $false; continue
    }
    if ($line -match '^\s*Clears:\s*(.+)$') {
      $entryClears += ($Matches[1] -split ',') | ForEach-Object { $_.Trim().Trim('`') } | Where-Object { $_ }
      continue
    }
    if ($line -match '^\s*\**Ruling:' -and $line -notmatch '(?i)pending') { $ruled = $true }
  }
  if ($ruled) { $globs += $entryClears }
  return $globs
}

$target = ($rest -replace '\\', '/')
$cleared = $false
try {
  $states = Get-ChildItem -Path '{{VAULT_DIR}}\tickets' -Filter 'state.md' -Recurse -Depth 1 -ErrorAction Stop
  foreach ($s in $states) {
    $txt = Get-Content -Path $s.FullName -Raw -ErrorAction Stop
    if ($txt -notmatch '(?m)^status:\s*(active|implemented-pending-review)\s*(#.*)?$') { continue }
    $ledger = Join-Path $s.DirectoryName 'council.md'
    if (-not (Test-Path $ledger)) { continue }
    foreach ($g in (Get-RuledClears $ledger)) {
      $pat = ($g -replace '\\', '/') -replace '\*\*', '*'
      if ($target -like $pat) { $cleared = $true; break }
    }
    if ($cleared) { break }
  }
} catch { exit 0 }

if ($cleared) { exit 0 }

$marker = Join-Path $env:TEMP "claude-council-off-$sid.txt"
$reason = "Council gate: '$norm' is a migration or contract path, which is hard to reverse after deploy, " +
  "and no ruled council ledger entry clears it (needs a 'Clears: <glob>' line on an entry whose Ruling is not " +
  "pending, in tickets\<id>\council.md of an active ticket). Do NOT edit yet. Run /council on the fork this " +
  "edit resolves (edit in place vs new migration, shape A vs shape B, and so on), have the user rule, then " +
  "record the ruling with a Clears line and re-issue the edit. User already ruled on this fork in chat and " +
  "wants no ledger? Ask them to confirm, then create $marker to bypass for this session."

@{ hookSpecificOutput = @{
    hookEventName            = 'PreToolUse'
    permissionDecision       = 'deny'
    permissionDecisionReason = $reason
} } | ConvertTo-Json -Compress
exit 0
