---
name: capture
version: 1.1.0
description: File substantive service knowledge learned this session into the right service folder-note(s) — the standing rule in the root schema. Use when the user says "capture", "/capture", "file what you learned", after a hook nudge that you touched a service repo, or before ending any session that investigated, debugged, or modified a service.
---

Capture what you learned about a service this session and file it into the durable folder-note(s), not just the ticket. This is the schema's capture standing rule made explicit. Be honest: filing nothing is the correct outcome for an orientation-only or trivial-edit session.

## Step 1 — Determine which services were touched

In priority order:

1. **Breadcrumb file (optional — only if the capture hooks are installed).** Read the session breadcrumb file (e.g. `$TEMP/claude-svc-<session_id>.txt`) if it exists — a PostToolUse hook appends the top-level repo name of every service file edited this session. Each line is one service dir under `{{ROOT_DIR}}`. If no hooks are installed, skip to 2.
2. **This session's edits and reads.** Any file under `{{ROOT_DIR}}/<Service>/...` you wrote, edited, or studied closely. Map the path to the precise folder-note: a file under a nested solution belongs to the nested service's page (e.g. `Parent/Parent.Sub/...` → `[[Parent.Sub]]`), not the parent. Use `{{VAULT_DIR}}/wiki/index.md` to resolve the exact folder-note name.
3. **The active ticket**, if one is in flight — its `services:` frontmatter.

If none of these yield a service, there is nothing to capture — say so and stop.

## Step 2 — For each touched service, ask: did I learn something substantive?

Substantive means at least one of:

- How a subsystem actually works (not what the code trivially shows)
- A non-obvious code path or control flow
- An architectural constraint or invariant
- A cross-service relationship (a call, a shared schema, an event, a build dependency)
- A gotcha, footgun, or failure mode (what breaks, under what condition, what error)

**Skip** what the code makes obvious on its own, and what is purely ticket-scoped (specific test data, a one-off repro, the PR number). When unsure whether it belongs on the folder-note, it probably does — err toward filing.

## Step 3 — File each keeper into its folder-note

For each service with something worth keeping, open `{{VAULT_DIR}}/wiki/services/<Name>/<Name>.md` and:

1. Add the knowledge to the **right section** — `## Architecture`, `## Relationships`, `## Build & Test`, `## Gotchas`, etc. Create the section if it doesn't exist. Match the terse house style in `wiki/standards/`.
2. If the new info **contradicts** what's already there, add a `> [!warning] Updated <YYYY-MM-DD>` callout next to the old claim rather than silently overwriting.
3. **Link back** to the ticket that surfaced it: `[[{{TICKET_PREFIX}}-NNNN]]`. Link related concepts/services with `[[wikilinks]]`.
4. If you learned a **cross-service relationship**, update the folder-note's relationship frontmatter (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`) using the exact property names from the schema. Add a one-line narrative in `## Relationships` for non-obvious edges. Then **rebuild** `{{VAULT_DIR}}/wiki/concepts/service-graph.md` from a full scan of all folder-notes (inverse lookups need every service), and log a `graph` entry.

## Step 3b — Sweep for prototype seeds

*(Skip this step if the builder-session module isn't installed — i.e. there is no `wiki/concepts/prototype-ideas.md`.)*

Re-scan everything you learned this session (kept *and* skipped — a thing too ticket-scoped to file can still be a seed) through the prototype lens of the schema's seed rule:

- Manual toil or a repetitive procedure that could be tooled away
- A missing inspector/dashboard/visualisation for something currently debugged by raw DB/log queries
- A constraint or workaround everyone routes around because there's no runway to fix it properly
- A "we could spike this with AI in an afternoon" moment

For each hit, append a seed entry to `{{VAULT_DIR}}/wiki/concepts/prototype-ideas.md` under `## Backlog` (pitch, pain wikilink to the folder-note/ticket, ambition, `status: seed`). First check the backlog for an existing entry covering the same pain — if one exists, strengthen its pain links instead of duplicating. Zero seeds is a normal outcome; do not invent ideas to have something to file.

## Step 4 — Record it

- Append to `{{VAULT_DIR}}/wiki/log.md`: `## [YYYY-MM-DD HH:MM] update | filed <Service> folder-note — <one-line summary> (from [[{{TICKET_PREFIX}}-NNNN]])`. Use the real current date/time.
- If you filed prototype seeds, fold them into the same log line (`+ N prototype seeds`).
- If you rebuilt the graph, also append the `graph | rebuilt service-graph (<N> services, <M> edges)` line.

## Step 5 — Report concisely

- One line per service filed: `<Service> — <what was added, which section>`.
- If you deliberately skipped something as obvious/ticket-only, say so in one line.
- If nothing was substantive, say "Nothing substantive to file" and stop — that is a valid, common outcome.

## When invoked from a Stop hook or PostToolUse nudge

*(Only applies if the capture hooks are installed — see the kit README. Without hooks, this skill runs on demand and the standing rule in the schema is the only reminder.)*

Do the full pass above, then return control. Do not start unrelated work. If a PostToolUse nudge fired mid-change, you may defer the actual filing to a natural stopping point — but do not let the session end without completing this pass (the Stop hook enforces that).
