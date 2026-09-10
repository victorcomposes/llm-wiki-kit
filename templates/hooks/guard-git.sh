#!/usr/bin/env bash
# PreToolUse guard on Bash for the git rules in the root schema, section 6 (POSIX variant, requires jq).
#   - no blanket staging: git add -A / --all; no git add -f
#   - commit subject '{{TICKET_PREFIX}}-NNNN <summary>' (id, space, summary, no colon);
#     vault maintenance without a ticket may use '<op>: <summary>'
#   - no commit body and no trailers
# Exit 2 = block the tool call, stderr goes to the agent. Fails open when the message cannot be
# parsed (amend --no-edit, -F file, -C sha). guard-git.ps1 is the reference implementation.
# NOTE: substitute {{ROOT_DIR}} and {{VAULT_DIR}} with forward-slash paths.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cmd" ] || exit 0
printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_])git([^[:alnum:]_]|$)' || exit 0

deny() { printf '%s\n' "$1" >&2; exit 2; }

# --- staging -----------------------------------------------------------------
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+add[^|;&]*[[:space:]](-[a-zA-Z]*A[a-zA-Z]*|--all)([[:space:]]|$)'; then
  deny "git guard: git add -A / --all is banned. Stage the explicit paths the change touched."
fi
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+add[^|;&]*[[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force)([[:space:]]|$)'; then
  deny "git guard: never git add -f a gitignored file; the exclusion is deliberate."
fi

# --- commit message ------------------------------------------------------------
printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit' || exit 0

# The repo being committed to: an explicit `git -C <path>` wins over the session cwd.
where=$(printf '%s' "$cmd" | sed -nE "s/.*git[[:space:]]+-C[[:space:]]+[\"']?([^[:space:]\"']+).*/\1/p" | head -1)
[ -n "$where" ] || where="$cwd"
case "$where" in "{{ROOT_DIR}}"*) ;; *) exit 0 ;; esac   # the schema's git rules apply to repos under {{ROOT_DIR}} only
is_vault=0
case "$where" in "{{VAULT_DIR}}"*) is_vault=1 ;; esac

# more -m flags than commits means a body on some commit
m_count=$(printf '%s' "$cmd" | grep -oE '[[:space:]]-m[[:space:]]' | wc -l | tr -d ' ')
c_count=$(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+commit' | wc -l | tr -d ' ')
[ "$m_count" -le "$c_count" ] || deny "git guard: more than one -m on a commit creates a body. Use a single subject line."

msg=''
if printf '%s' "$cmd" | grep -qE "<<-?[[:space:]]*[\"']?[A-Za-z_]+"; then
  # heredoc: lines between the marker line and the terminator
  msg=$(printf '%s\n' "$cmd" | awk '
    !f && match($0, /<<-?[[:space:]]*["'\'']?[A-Za-z_]+/) { m = substr($0, RSTART, RLENGTH); sub(/<<-?[[:space:]]*["'\'']?/, "", m); f = 1; next }
    f && $0 ~ ("^[[:space:]]*" m "[[:space:]]*\\)?[[:space:]]*$") { exit }
    f { print }')
else
  msg=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+commit[^"]*[[:space:]]-m[[:space:]]*"([^"]*)".*/\1/p' | head -1)
  [ -n "$msg" ] || msg=$(printf '%s' "$cmd" | sed -nE "s/.*git[[:space:]]+commit[^']*[[:space:]]-m[[:space:]]*'([^']*)'.*/\1/p" | head -1)
fi
[ -n "$msg" ] || exit 0

subject=$(printf '%s\n' "$msg" | head -n 1 | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
ok=0
printf '%s' "$subject" | grep -qE '^{{TICKET_PREFIX}}-[0-9]+ [^[:space:]]' && ok=1
if [ "$ok" = 0 ] && [ "$is_vault" = 1 ]; then
  printf '%s' "$subject" | grep -qE '^[a-z][a-z-]*: [^[:space:]]' && ok=1
fi
if [ "$ok" = 0 ]; then
  alt=''; [ "$is_vault" = 1 ] && alt=" or '<op>: <summary>' for vault maintenance without a ticket"
  deny "git guard: commit subject '$subject' must be '{{TICKET_PREFIX}}-NNNN <summary>' (ticket id, one space, summary, no colon)$alt."
fi

body=$(printf '%s\n' "$msg" | tail -n +2 | grep -vE '^[[:space:]]*$')
[ -z "$body" ] || deny "git guard: commit body and trailers are not allowed. Keep the subject line only."

exit 0
