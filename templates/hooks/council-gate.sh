#!/usr/bin/env bash
# PreToolUse hook - the council step before a hard-to-reverse edit (POSIX variant, requires jq).
# Denies an Edit/Write to a MIGRATION or CONTRACT path under {{ROOT_DIR}}/<Service>/ unless a ruled
# council ledger entry in an active ticket clears it: a `Clears: <glob>, <glob>` line (relative to
# {{ROOT_DIR}}, `*`/`**`) on an entry whose `Ruling:` line is not pending, in tickets/<id>/council.md.
# Bypass: $TMPDIR/claude-council-off-<session_id>.txt. council-gate.ps1 is the reference implementation.
# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with forward-slash paths.
# ponytail: fail-open on any error. ** is folded to * so a glob only widens.

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

# Print the Clears globs of ruled entries in one ledger, one per line.
ruled_clears() {
  awk '
    /^##[[:space:]]/ { if (ruled) print buf; buf=""; ruled=0; next }
    /^[[:space:]]*Clears:/ { sub(/^[[:space:]]*Clears:[[:space:]]*/, ""); buf = buf (buf==""?"":",") $0; next }
    /^[[:space:]]*\**Ruling:/ && tolower($0) !~ /pending/ { ruled=1 }
    END { if (ruled) print buf }
  ' "$1" | tr ',' '\n' | sed 's/^[[:space:]`]*//; s/[[:space:]`]*$//' | grep -v '^$'
}

for st in '{{VAULT_DIR}}'/tickets/*/state.md; do
  [ -f "$st" ] || continue
  grep -qE '^status:[[:space:]]*(active|implemented-pending-review)[[:space:]]*(#.*)?$' "$st" || continue
  ledger="$(dirname "$st")/council.md"
  [ -f "$ledger" ] || continue
  while IFS= read -r g; do
    pat=$(printf '%s' "$g" | sed 's#\#/#g; s#\*\*#*#g')
    # shellcheck disable=SC2254
    case "$rest" in $pat) exit 0 ;; esac
  done < <(ruled_clears "$ledger")
done

printf '%s\n' "Council gate: '$fp' is a migration or contract path, which is hard to reverse after deploy, and no ruled council ledger entry clears it (needs a 'Clears: <glob>' line on an entry whose Ruling is not pending, in tickets/<id>/council.md of an active ticket). Do NOT edit yet. Run /council on the fork this edit resolves, have the user rule, record the ruling with a Clears line, then re-issue the edit. User already ruled in chat and wants no ledger? Ask them to confirm, then create $marker to bypass for this session." >&2
exit 2
