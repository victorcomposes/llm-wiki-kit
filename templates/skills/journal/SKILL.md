---
name: journal
version: 1.1.0
description: Append a brief session/day summary to the current month's journal and prompt for brag-worthy items. Use when the user says "journal", "/journal", "log the day", "end of day", or wraps a session and wants it recorded.
---

Update the journal for the current month at `{{VAULT_DIR}}/wiki/journal/YYYY-MM.md` (use the current date in the user's context).

## Steps

1. If the file doesn't exist, create it with frontmatter:
   ```yaml
   ---
   type: journal
   month: YYYY-MM
   ---

   # Journal — <Month Year>
   ```
2. Read the most recent entries in `{{VAULT_DIR}}/wiki/log.md` (the last 24 hours, or since the last journal entry — whichever is more). Use these as raw material for the summary.
3. Append a new section to the journal:
   ```
   ## YYYY-MM-DD

   <2-5 sentence narrative of what happened: what tickets moved, what was learned,
    what's still in flight, any decisions made. Cross-reference with [[wikilinks]]
    to tickets and concept pages where relevant.>
   ```
4. If the user is present (interactive session), ask: *"Anything worth promoting to `brag.md`?"* — typical brag-worthy items: a ticket merged, a tricky bug found, a piece of infra unblocked, a doc that took something cross-team from murky to obvious. Append confirmed items to `{{VAULT_DIR}}/wiki/brag.md` under a `## YYYY-MM` section.
5. **Builder-session closure** *(only if `wiki/concepts/prototype-ideas.md` exists)*: if today's work included building/demoing a prototype (check the log entries and the session itself), flip the matching backlog entry's status to `built` (link the demo/repo/brag line) and make sure the build came up in step 4's brag prompt. A `spark` run with no build yet needs nothing.
6. Append to `wiki/log.md`:
   `## [YYYY-MM-DD HH:MM] journal | updated <YYYY-MM> journal`
7. Report: which entry was added, and (if applicable) what was added to brag.

Keep entries terse. The journal is a low-friction record, not a daily essay.
