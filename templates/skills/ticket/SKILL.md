---
name: ticket
version: 1.7.1
description: Scaffold a new ticket folder under {{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/ with state, context, plan, notes, and create matching feature branches in affected service repos. Use when the user says "ticket {{TICKET_PREFIX}}-NNNN", "/ticket {{TICKET_PREFIX}}-NNNN", "scaffold a ticket", or "start work on {{TICKET_PREFIX}}-NNNN".
---

Create a new ticket workspace for the ticket the user named (expect a `{{TICKET_PREFIX}}-NNNN`, or a `VLT-NNNN` placeholder, identifier in the invocation — if absent, ask). Tracker: {{TRACKER_NAME}} ({{TRACKER_URL}}).

## Steps

1. Validate the identifier matches `({{TICKET_PREFIX}}|VLT)-\d+` — real tracker ids are `{{TICKET_PREFIX}}-NNNN`; use a `VLT-NNNN` placeholder when the tracker hasn't assigned an id yet (root schema §4). If it matches neither, ask the user to re-issue. Throughout the steps below, `{{TICKET_PREFIX}}-NNNN` stands for the actual id (either form) — folder, files, branches, and log entries all use it verbatim.
2. Check whether `{{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/` **or `{{VAULT_DIR}}/tickets/_archive/{{TICKET_PREFIX}}-NNNN/`** already exists. If it does, read `state.md` and ask the user whether they want to add to the existing folder rather than scaffold a new one. **Reopening an archived ticket is `git mv tickets/_archive/{{TICKET_PREFIX}}-NNNN tickets/{{TICKET_PREFIX}}-NNNN` plus setting `status: active` — never scaffold a duplicate over an archived id, or `[[{{TICKET_PREFIX}}-NNNN]]` becomes ambiguous between two folder-notes.**
3. Ask the user for:
   - One-paragraph brief of what the ticket is about (you'll turn this into `notes.md`)
   - The {{TRACKER_NAME}} URL or summary line if they have it (base: {{TRACKER_URL}})
   - Which services they think will be affected (you'll cross-check against the folders under `{{VAULT_DIR}}/wiki/services/` and confirm)
4. Create the folder and five files:
   - `state.md` with frontmatter (`ticket`, `status: active`, `created: <today>`, `services: []`, `branches: []`, `tickets-related: []`, `needs-human: []`) and a one-paragraph "current focus" body. `needs-human` holds items only a human can decide or run: each one `{what, run, proves}`; a database/environment query outside the local instance goes in `tickets/{{TICKET_PREFIX}}-NNNN/sql/NN-<slug>.sql` rather than inline.
   - `notes.md` containing the user's brief verbatim, followed by a `## PAUSE (frame before coding)` block — five one-line answers seeded from the brief, to sharpen before implementation (the Assumptions line later feeds `plan.md`'s `## Assumptions`):
     - **Problem** — what is the real problem?
     - **Assumptions** — what do I know vs assume?
     - **Urgency** — what is the impact or risk?
     - **Small step** — what is the next safe action?
     - **Explain** — what should I say clearly now?
   - `plan.md` skeleton with sections `## Summary`, `## Key Changes`, `## Public Interfaces`, `## Test Plan`, `## Assumptions` — leave content empty for the agent to fill once it has read the relevant service code. `## Key Changes` is a **numbered list** so each step is individually addressable. Seed the file with this stability note at the top, under the frontmatter: `> Once approved, this plan is edited surgically — change requests touch only the named step and leave the rest verbatim (root schema §5). Reference steps by number.`
   - `context.md` skeleton with sections `## Status`, `## Branches Checked`, `## <Per-service notes>`, `## Verification Notes` — leave empty.
   - `{{TICKET_PREFIX}}-NNNN.md` — a thin folder-note: an H1 title and pointers (wikilinks) to the four work files above; **no status duplication**. This is what makes `[[{{TICKET_PREFIX}}-NNNN]]` resolve vault-wide (root schema §4).
5. For each affected service, link the new ticket from `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` (the folder-note) under a "Related tickets" section (create the section if it doesn't exist). Use `[[{{TICKET_PREFIX}}-NNNN]]` wikilinks. If a service folder doesn't exist yet, flag it for the user — do not auto-create.
6. For each affected service repo that exists under `{{ROOT_DIR}}`, create a feature branch named `feature/{{TICKET_PREFIX}}-NNNN-<short-summary>` (never a bare `feature/{{TICKET_PREFIX}}-NNNN`):
   - Derive `<short-summary>` from the ticket brief — a short kebab-case description of the work, ≈2–5 words (e.g. `feature/{{TICKET_PREFIX}}-1827-credit-insurance-transition-lockout`). Use the same summary across every affected repo for this ticket.
   - Find the repo root (the directory under `{{ROOT_DIR}}` that contains a `.git` folder and corresponds to the service).
   - Run `git checkout -b feature/{{TICKET_PREFIX}}-NNNN-<short-summary>` in that repo. If a branch for this ticket already exists, check it out instead and note it was pre-existing; if it exists as a bare `feature/{{TICKET_PREFIX}}-NNNN`, `git branch -m` it to add the summary.
   - Record each branch in `state.md` frontmatter under `branches: []` and in the `## Branches Checked` section of `context.md`.
   - If a repo cannot be found or git fails, flag it — do not abort the whole scaffold.
7. Append an entry to `{{VAULT_DIR}}/wiki/log.md`:
   `## [YYYY-MM-DD HH:MM] ticket | scaffolded {{TICKET_PREFIX}}-NNNN — <one-line brief>`
8. Report back: where the folder lives, what files were created, which service pages were updated, which branches were created, and what you'd suggest doing next (typically: read the affected service code and draft `plan.md`). If the `grill-me` companion skill is installed, mention that once `plan.md` is drafted, `/grill-me` is the way to stress-test it before implementation — fold the surviving decisions back into `plan.md`.

Honour the conventions in the root schema (frontmatter, wikilinks, ticket structure).
