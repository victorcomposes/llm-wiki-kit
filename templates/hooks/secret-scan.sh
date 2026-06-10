#!/usr/bin/env bash
# PreToolUse guard (vault-scope settings): block `git commit` while staged vault
# changes contain secret-shaped strings. Record where a credential lives (Key
# Vault, variable group), never its value. Exit 2 = block the tool call, stderr
# goes to Claude. Runs under bash on all OSes (Git Bash on Windows ships with git).
# NOTE: substitute {{VAULT_DIR}} with a forward-slash path.

input=$(cat)
echo "$input" | grep -q 'git commit' || exit 0

PAT='-----BEGIN [A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{20,}\.eyJ|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|(password|passwd|secret|api[_-]?key|access[_-]?token|client[_-]?secret|connection[_-]?string)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"'<$ ]{12,}'

hits=$(git -C "{{VAULT_DIR}}" diff --cached | grep -nE -e "$PAT" | head -5)
if [ -n "$hits" ]; then
  {
    echo "Blocked: staged vault changes contain secret-shaped content."
    echo "Replace the value with a reference to where it lives (Key Vault, variable group), then re-stage."
    echo "$hits"
  } >&2
  exit 2
fi
exit 0
