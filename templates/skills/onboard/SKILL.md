---
name: onboard
version: 1.1.0
description: Orient a fresh agent in {{ROOT_DIR}} — read the schema, list active tickets, point at relevant services. Use when the user says "onboard", "/onboard", "orient yourself", "what's in flight", or starts a fresh session and wants a status briefing before any work begins.
---

You are starting a fresh session under `{{ROOT_DIR}}`. Orient yourself before doing anything else.

## Steps

1. Read the root schema (`{{ROOT_DIR}}/CLAUDE.md`, or `{{ROOT_DIR}}/AGENTS.md` if that's your agent's file) if it isn't already in context. Confirm you understand: vault location (`{{VAULT_DIR}}`), the operations, the wikilink/frontmatter conventions, the git rules, and the behaviour guidelines.
2. Read `{{VAULT_DIR}}/wiki/index.md`. This is the catalogue. Note the categories and the most recently updated pages.
3. Read `{{VAULT_DIR}}/wiki/concepts/service-graph.md` — the rolled-up service-to-service relationship map. Skim it before reading any ticket so you arrive with cross-service context: which services call which, which are upstream of others, and which would break if a given service changes.
4. List every directory under `{{VAULT_DIR}}/tickets/`. For each `{{TICKET_PREFIX}}-NNNN/state.md`, read the frontmatter — collect tickets where `status` is `active`, `investigated`, or `implemented-pending-review`. For each active ticket, cross-reference the affected services against the graph from Step 3 — note any services downstream of the ticket's targets (they're potential blast-radius).
5. Read the last 10 lines of `{{VAULT_DIR}}/wiki/log.md` to see what happened recently.
6. Read the current month's journal at `{{VAULT_DIR}}/wiki/journal/YYYY-MM.md` (current date is in the user's context).

## Report to the user, concisely

- **In-flight tickets** — one line per ticket: `{{TICKET_PREFIX}}-NNNN (status) — <one-line state>`. Group by status.
- **Services in active rotation** — services that appear in active-ticket frontmatter. For each, note whether a per-service schema file exists at `{{ROOT_DIR}}/<Service>/CLAUDE.md` (or `AGENTS.md`).
- **Blast radius from the service graph** — for each service touched by an active ticket, list the services that are downstream (declare `calls`/`depends_on`/`subscribes_to` against it). These are the candidates to regression-test or notify when the ticket ships. Skip this line if the graph has no edges yet.
- **Recent log entries** — the 3 most recent meaningful lines from `log.md` (skip pure `session` lines if there's something more interesting).
- **What's blocking** — anything in `state.md` files flagged as blocked, waiting, or pending external action.

Do not start any work. Just report. The user will pick the next thing to do.

If `{{VAULT_DIR}}/wiki/index.md` does not exist yet, say so and suggest running `/lint` to bootstrap the catalogue. If `{{VAULT_DIR}}/wiki/concepts/service-graph.md` is missing, the vault was scaffolded before the relationship-frontmatter convention — recommend re-running setup in Update mode to create it.
