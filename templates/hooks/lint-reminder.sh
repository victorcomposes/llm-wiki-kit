#!/usr/bin/env bash
# SessionStart hook (vault-scope settings): one-line tip if no /lint ran recently.
# Marker = the most recent "lint |" action entry in wiki/log.md, so the reminder
# resets whenever a lint run is logged per the log.md convention.
# Lint runs are user-initiated (/lint); deliberately no scheduled task.
# NOTE: substitute {{VAULT_DIR}} with a forward-slash path.

LOG="{{VAULT_DIR}}/wiki/log.md"
[ -f "$LOG" ] || exit 0

last=$(grep -E '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}[^]]*\] lint \|' "$LOG" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)

if [ -z "$last" ]; then
  printf '{"systemMessage":"Tip: no /lint recorded in log.md yet -- run /lint for a vault health check."}'
  exit 0
fi

# GNU date first, BSD (macOS) date as fallback.
then_s=$(date -d "$last" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$last" +%s 2>/dev/null) || exit 0
[ -n "$then_s" ] || exit 0
days=$(( ($(date +%s) - then_s) / 86400 ))
if [ "$days" -ge 7 ]; then
  printf '{"systemMessage":"Tip: last /lint was %s days ago (%s) -- consider a vault health check."}' "$days" "$last"
fi
exit 0
