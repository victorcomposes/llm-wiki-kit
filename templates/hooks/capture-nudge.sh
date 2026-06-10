#!/usr/bin/env bash
# PostToolUse hook — nudges the agent to file service knowledge while it's fresh.
# POSIX variant (macOS/Linux). Requires jq. Referenced from ~/.claude/settings.json
# so it fires in every {{ROOT_DIR}} session (settings.json does NOT cascade).
# Fires after a file under {{ROOT_DIR}}/<Service>/ is modified. Once per service
# per session (breadcrumb file in $TMPDIR), so it never spams during multi-file
# edits. The same breadcrumb is consumed by /capture and by stop-nudge.sh.
# NOTE: in this file {{ROOT_DIR}} and {{VAULT_DIR}} must be substituted with
# forward-slash paths.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac

fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$fp" ] || exit 0

ROOT='{{ROOT_DIR}}'
case "$fp" in "$ROOT"/*) ;; *) exit 0 ;; esac

# First path segment under the root is the service repo dir.
rest=${fp#"$ROOT"/}
seg=${rest%%/*}
# A file directly under the root (e.g. CLAUDE.md) is not a service repo.
[ "$seg" = "$rest" ] && exit 0
[ -n "$seg" ] || exit 0
# Skip the vault itself and any dotfolder (.vault, .claude, .git, ...).
case "$seg" in .*) exit 0 ;; esac

# Breadcrumb: one service per line, keyed by session. Dedup => once per service.
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
crumb="${TMPDIR:-/tmp}/claude-svc-$sid.txt"
grep -qxF "$seg" "$crumb" 2>/dev/null && exit 0
printf '%s\n' "$seg" >> "$crumb"

msg="You just modified a file in the '$seg' service repo ($fp). \
Per the root schema's capture standing rule, when you reach a natural stopping point in this change, \
run /capture to file any substantive knowledge you gained about '$seg' \
(how a subsystem works, a non-obvious code path, an architectural constraint, a cross-service \
relationship, a gotcha or failure mode) into its folder-note under \
{{VAULT_DIR}}/wiki/services/ - pick the precise nested folder-note matching the path. \
If nothing substantive came up, no action needed. This nudge fires once per service per session."

jq -cn --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
exit 0
