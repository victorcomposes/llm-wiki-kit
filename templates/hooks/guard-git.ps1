$ErrorActionPreference = 'Stop'

# PreToolUse guard on Bash|PowerShell for the git rules in the root schema, section 6 (Windows variant):
#   - no blanket staging: git add -A / --all; no git add -f
#   - commit subject '{{TICKET_PREFIX}}-NNNN <summary>' (id, space, summary, no colon); vault maintenance may use '<op>: <summary>'
#   - no commit body and no trailers
# Fails open when the message cannot be parsed (amend --no-edit, -F file, -C sha).
# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with native backslash paths.

function Deny([string]$Reason) {
    @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Depth 4 -Compress
    exit 0
}

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrWhiteSpace($cmd) -or $cmd -notmatch '\bgit\b') { exit 0 }

# --- staging -----------------------------------------------------------------
if ($cmd -match '\bgit\s+add\b[^|;&\r\n]*?\s(-[a-zA-Z]*A[a-zA-Z]*|--all)(\s|$)') {
    Deny 'git guard: git add -A / --all is banned (it swept a stray file and a zero-byte truncation into master). Stage the explicit paths the change touched.'
}
if ($cmd -match '\bgit\s+add\b[^|;&\r\n]*?\s(-[a-zA-Z]*f[a-zA-Z]*|--force)(\s|$)') {
    Deny 'git guard: never git add -f a gitignored file; the exclusion is deliberate.'
}

# --- commit message ------------------------------------------------------------
if ($cmd -notmatch '\bgit\s+commit\b') { exit 0 }

# The repo being committed to: an explicit `git -C <path>` wins over the session cwd.
$where = [string]$payload.cwd
if ($cmd -match '\bgit\s+-C\s+[''"]?([^\s''"]+)') { $where = $Matches[1] }
$whereNorm = $where -replace '/', '\'
if ($whereNorm -notlike '{{ROOT_DIR}}\*') { exit 0 }   # the schema's git rules apply to repos under {{ROOT_DIR}} only
$isVault = $whereNorm -like '{{VAULT_DIR}}*'

$msg = $null
if ($cmd -match '(?s)<<-?\s*[''"]?(\w+)[''"]?\s*\r?\n(.*?)\r?\n\s*\1\s*(\r?\n|\)|$)') {
    $msg = $Matches[2]                                   # bash heredoc: -m "$(cat <<'EOF' ... EOF)"
} elseif ($cmd -match '(?s)@[''"]\s*\r?\n(.*?)\r?\n[''"]@') {
    $msg = $Matches[1]                                   # powershell here-string
} elseif ($cmd -match '(?s)\bgit\s+commit\b.*?\s-m\s*"([^"]*)"') {
    $msg = $Matches[1]
} elseif ($cmd -match '(?s)\bgit\s+commit\b.*?\s-m\s*''([^'']*)''') {
    $msg = $Matches[1]
}

foreach ($seg in @([regex]::Split($cmd, '\bgit\s+commit\b') | Select-Object -Skip 1)) {
    if (([regex]::Matches($seg, '\s-m\s')).Count -gt 1) {
        Deny 'git guard: more than one -m on a commit creates a body. Use a single subject line.'
    }
}

if ($null -eq $msg) { exit 0 }

$lines   = @($msg -split '\r?\n')
$subject = $lines[0].Trim()

$ok = $subject -match '^{{TICKET_PREFIX}}-\d+ \S'
if (-not $ok -and $isVault -and $subject -match '^[a-z][a-z-]*: \S') { $ok = $true }
if (-not $ok) {
    $alt = if ($isVault) { " or '<op>: <summary>' for vault maintenance without a ticket" } else { '' }
    Deny ("git guard: commit subject '" + $subject + "' must be '{{TICKET_PREFIX}}-NNNN <summary>' (ticket id, one space, summary, no colon)" + $alt + '.')
}

$body = @($lines | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne '' })
if ($body.Count -gt 0) {
    Deny 'git guard: commit body and trailers are not allowed. Keep the subject line only.'
}

exit 0
