---
name: journal
version: 1.3.1
description: Append a brief session/day summary to the current month's journal and prompt for brag-worthy items. Use when the user says "journal", "/journal", "log the day", "end of day", or wraps a session and wants it recorded.
---

Update the journal for the current month at `{{VAULT_DIR}}/wiki/journal/YYYY-MM.md` (use the current date in the user's context).

## Steps

1. If the file doesn't exist, create it with frontmatter:
   ```yaml
   ---
   type: journal
   date: YYYY-MM-DD
   month: YYYY-MM
   tags: []
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
4. **Growth OS reflection** *(interactive sessions; skip days with no substantive engineering call)* — practise the PAUSE/KARN frameworks against the real day:
   a. **KARN status** — frame the day's hardest call as a one-line block appended inside today's journal entry:
      `> **KARN** — Known: <confirmed> · Assumption: <still verifying> · Risk: <what could be affected> · Next: <what happens next>`
   b. **Evidence** — capture one promotion/interview-grade win as a dated, categorised line in `wiki/journal/evidence-log.md` (create it on first use with `type: journal`, `date:`, `tags: []` frontmatter and add it to `wiki/index.md`). Category ∈ {problem clarity, system design, product judgment, reliability, communication, leadership, domain mastery, business impact}. Format:
      `- YYYY-MM-DD · <category> · **<title>** — <what you did and the proof/metric> [[{{TICKET_PREFIX}}-NNNN]]`
      Ask for category/title if not obvious; the same win can feed both this line and the brag prompt below.
5. If the user is present (interactive session), ask: *"Anything worth promoting to `brag.md`?"* — typical brag-worthy items: a ticket merged, a tricky bug found, a piece of infra unblocked, a doc that took something cross-team from murky to obvious. Append confirmed items to `{{VAULT_DIR}}/wiki/brag.md` under a `## YYYY-MM` section.
6. **Builder-session closure** *(only if `wiki/concepts/prototype-ideas.md` exists)*: if today's work included building/demoing a prototype (check the log entries and the session itself), flip the matching backlog entry's status to `built` (link the demo/repo/brag line) and make sure the build came up in step 5's brag prompt. A `spark` run with no build yet needs nothing.
7. Append to `wiki/log.md`:
   `## [YYYY-MM-DD HH:MM] journal | updated <YYYY-MM> journal`
8. Report: which entry was added, and (if applicable) what was added to brag and the evidence log.

Keep entries terse. The journal is a low-friction record, not a daily essay.
