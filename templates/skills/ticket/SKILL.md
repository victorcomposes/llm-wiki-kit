---
name: ticket
version: 1.2.0
description: Scaffold a new ticket folder under {{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/ with state, context, plan, notes, and create matching feature branches in affected service repos. Use when the user says "ticket {{TICKET_PREFIX}}-NNNN", "/ticket {{TICKET_PREFIX}}-NNNN", "scaffold a ticket", or "start work on {{TICKET_PREFIX}}-NNNN".
---

Create a new ticket workspace for the ticket the user named (expect a `{{TICKET_PREFIX}}-NNNN` identifier in the invocation — if absent, ask). Tracker: {{TRACKER_NAME}} ({{TRACKER_URL}}).

## Steps

1. Validate the identifier matches `{{TICKET_PREFIX}}-\d+`. If not, ask the user to re-issue with the correct format.
2. Check whether `{{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/` already exists. If it does, read `state.md` and ask the user whether they want to add to the existing folder rather than scaffold a new one.
3. Ask the user for:
   - One-paragraph brief of what the ticket is about (you'll turn this into `notes.md`)
   - The {{TRACKER_NAME}} URL or summary line if they have it (base: {{TRACKER_URL}})
   - Which services they think will be affected (you'll cross-check against the folders under `{{VAULT_DIR}}/wiki/services/` and confirm)
4. Create the folder and four files:
   - `state.md` with frontmatter (`ticket`, `status: active`, `created: <today>`, `services: []`, `branches: []`, `tickets-related: []`) and a one-paragraph "current focus" body.
   - `notes.md` containing the user's brief verbatim.
   - `plan.md` skeleton with sections `## Summary`, `## Key Changes`, `## Public Interfaces`, `## Test Plan`, `## Assumptions` — leave content empty for the agent to fill once it has read the relevant service code.
   - `context.md` skeleton with sections `## Status`, `## Branches Checked`, `## <Per-service notes>`, `## Verification Notes` — leave empty.
5. For each affected service, link the new ticket from `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` (the folder-note) under a "Related tickets" section (create the section if it doesn't exist). Use `[[{{TICKET_PREFIX}}-NNNN]]` wikilinks. If a service folder doesn't exist yet, flag it for the user — do not auto-create.
6. For each affected service repo that exists under `{{ROOT_DIR}}`, create a feature branch named `feature/{{TICKET_PREFIX}}-NNNN`:
   - Find the repo root (the directory under `{{ROOT_DIR}}` that contains a `.git` folder and corresponds to the service).
   - Run `git checkout -b feature/{{TICKET_PREFIX}}-NNNN` in that repo. If the branch already exists, check it out instead and note it was pre-existing.
   - Record each branch in `state.md` frontmatter under `branches: []` and in the `## Branches Checked` section of `context.md`.
   - If a repo cannot be found or git fails, flag it — do not abort the whole scaffold.
7. Append an entry to `{{VAULT_DIR}}/wiki/log.md`:
   `## [YYYY-MM-DD HH:MM] ticket | scaffolded {{TICKET_PREFIX}}-NNNN — <one-line brief>`
8. Report back: where the folder lives, what files were created, which service pages were updated, which branches were created, and what you'd suggest doing next (typically: read the affected service code and draft `plan.md`). If the `grill-me` companion skill is installed, mention that once `plan.md` is drafted, `/grill-me` is the way to stress-test it before implementation — fold the surviving decisions back into `plan.md`.

Honour the conventions in the root schema (frontmatter, wikilinks, ticket structure).
