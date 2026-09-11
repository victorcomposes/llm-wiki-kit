#!/usr/bin/env bash
# PreToolUse hook - the council step before a hard-to-reverse edit (POSIX variant, requires jq).
# Denies an Edit/Write to a MIGRATION or CONTRACT path under {{ROOT_DIR}}/<Service>/ until an
# active ticket carries tickets/<id>/council.md (written by /council).
# Bypass: $TMPDIR/claude-council-off-<session_id>.txt. council-gate.ps1 is the reference implementation.
# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with forward-slash paths.
# ponytail: fail-open on any error.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$fp" ] || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')

root='{{ROOT_DIR}}'
case "$fp" in "$root"/*) ;; *) exit 0 ;; esac
rest=${fp#"$root"/}
case "$rest" in */*) ;; *) exit 0 ;; esac
case "$rest" in .*) exit 0 ;; esac

printf '%s' "$fp" | grep -qiE '\.(cs|ts|sql|json)$' || exit 0
printf '%s' "$fp" | grep -qiE '/(Migrations|Contracts|DTOs|Dto)/|(DTO|Dto|Contract|Event)\.cs$' || exit 0

marker="${TMPDIR:-/tmp}/claude-council-off-$sid.txt"
[ -f "$marker" ] && exit 0

for st in '{{VAULT_DIR}}'/tickets/*/state.md; do
  [ -f "$st" ] || continue
  grep -qE '^status:[[:space:]]*(active|implemented-pending-review)[[:space:]]*(#.*)?$' "$st" || continue
  [ -f "$(dirname "$st")/council.md" ] && exit 0
done

printf '%s\n' "Council gate: '$fp' is a migration or contract path, which is hard to reverse after deploy, and no active ticket has a tickets/<id>/council.md. Do NOT edit yet. Run /council on the fork this edit resolves: three fresh-context seats judge it, the decision lands in council.md with its dissent, the user rules, then re-issue the edit. User has already ruled on this fork? Ask them to confirm, then create $marker to bypass for this session." >&2
exit 2
