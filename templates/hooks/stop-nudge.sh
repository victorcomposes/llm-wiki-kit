#!/usr/bin/env bash
# Stop hook for every {{ROOT_DIR}} session — POSIX variant (macOS/Linux).
# Requires jq. Referenced from ~/.claude/settings.json. Two duties, one hook:
#   1. If a service repo was touched this session (breadcrumb from
#      capture-nudge.sh) and we haven't nagged yet, block ONCE with the
#      capture reminder. A .nagged marker prevents re-blocking every turn;
#      the breadcrumb itself is left for /capture to consume.
#   2. Otherwise, if the vault has uncommitted changes, show a bookkeeping
#      nudge (log.md / index.md / commit). Silent when the tree is clean.
# NOTE: substitute {{ROOT_DIR}} / {{VAULT_DIR}} with forward-slash paths.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
case "$cwd" in '{{ROOT_DIR}}'*) ;; *) exit 0 ;; esac

sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
crumb="${TMPDIR:-/tmp}/claude-svc-$sid.txt"
nagged="${TMPDIR:-/tmp}/claude-svc-$sid.nagged"

if [ -f "$crumb" ] && [ ! -f "$nagged" ]; then
  : > "$nagged"
  reason="Before ending this session: per the root schema's capture standing rule, check whether you learned anything substantive about a service this session (how a subsystem works, a non-obvious code path, an architectural constraint, a cross-service relationship, a gotcha or failure mode). If so, file it into that service's folder-note at {{VAULT_DIR}}/wiki/services/<Name>/<Name>.md before stopping - not only in the ticket. If nothing substantive came up, or it is already filed, briefly say so and stop."
  jq -cn --arg r "$reason" '{decision:"block",reason:$r}'
  exit 0
fi

dirty=$(git -C '{{VAULT_DIR}}' status --porcelain 2>/dev/null | grep -c .)
if [ "$dirty" -gt 0 ]; then
  jq -cn --arg m "Vault bookkeeping: $dirty uncommitted change(s) -- file knowledge to folder-notes, update log.md/index.md, and commit before wrapping up." '{systemMessage:$m}'
fi
exit 0
