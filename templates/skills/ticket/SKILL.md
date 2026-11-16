---
name: ticket
version: 1.14.0
description: Scaffold a new ticket folder under {{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/ with {{TICKET_PREFIX}}-NNNN.md, state.md, plan.md and evidence/, and link it from the affected service folder-notes. Use when the user says "ticket {{TICKET_PREFIX}}-NNNN", "/ticket {{TICKET_PREFIX}}-NNNN", "scaffold a ticket", or "start work on {{TICKET_PREFIX}}-NNNN".
---

Create a new ticket folder for the ticket the user named. Expect a `{{TICKET_PREFIX}}-NNNN` id, or a `VLT-NNNN` placeholder, in the invocation. If it is absent, ask. Tracker: {{TRACKER_NAME}} ({{TRACKER_URL}}).

## Steps

1. Validate the id against `({{TICKET_PREFIX}}|VLT)-\d+`. Real tracker ids are `{{TICKET_PREFIX}}-NNNN`. Use a `VLT-NNNN` placeholder when the tracker has no id yet (root schema §4). If the id matches neither, ask the user to give it again. Below, `{{TICKET_PREFIX}}-NNNN` stands for the actual id. The folder, the files and the log entry use it verbatim.
2. Check whether `{{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/` or `{{VAULT_DIR}}/tickets/_archive/{{TICKET_PREFIX}}-NNNN/` exists. If it does, read `state.md` and resume in that folder. Do not scaffold a new one. Reopen an archived ticket with `git mv tickets/_archive/{{TICKET_PREFIX}}-NNNN tickets/{{TICKET_PREFIX}}-NNNN`, and set `status: investigated` until a new plan is approved. Never scaffold a duplicate over an archived id.
3. Get the brief, the {{TRACKER_NAME}} summary and the affected services from the invocation and the {{TRACKER_NAME}} ticket. Ask the user only for what neither gives. Check the services against the folders under `{{VAULT_DIR}}/wiki/services/`.
4. Create the folder with `{{TICKET_PREFIX}}-NNNN.md`, `state.md`, `plan.md` and an empty `evidence/` folder. Create nothing else.
   - `{{TICKET_PREFIX}}-NNNN.md`: a generated page so that `[[{{TICKET_PREFIX}}-NNNN]]` resolves in Obsidian. `type: ticket` frontmatter, then `# {{TICKET_PREFIX}}-NNNN <tracker summary>` and one line: `[[state]] - [[plan]] - [[review]]`. Nothing else. Nobody updates it later.
   - `state.md` frontmatter: `type: ticket`, `ticket`, `status: investigated`, `created: <today>`, `kind:` (blank; set to `bug` or `feature` in the plan step), `services: []`, `branches: []`, `tickets-related: []`, `needs-human: []`. Body: one paragraph of current focus. `step:` and `updated:` are optional. A `needs-human` item is `{what, run, proves}`. A database or environment query outside the local instance goes in `tickets/{{TICKET_PREFIX}}-NNNN/sql/NN-<slug>.sql`.
   - `plan.md`: `type: ticket` and `date:` frontmatter, then the empty sections `## Problem`, `## Key Changes`, `## Proof`, `## Prior rulings`. Add `## Reproduction` for a bug. Put the brief verbatim under `## Problem`. `## Key Changes` is a numbered list. Put this note under the frontmatter: `> Once approved, this plan is edited surgically - change requests touch only the named step and leave the rest verbatim. Reference steps by number.`
   - Created later, when needed: `review.md` (by the `review-loop` skill), `sql/NN-<slug>.sql`, `handoff.md`. Every non-`.md` file goes in `evidence/`.
5. For each affected service, link the new ticket from `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` under a "Related tickets" section. Create the section if it does not exist. Use `[[{{TICKET_PREFIX}}-NNNN]]` wikilinks. If a service folder does not exist, flag it to the user. Do not create it.
6. Do not create branches. The agent that starts the code work cuts `feature/{{TICKET_PREFIX}}-NNNN-<short-summary>` in each affected repo (root schema §6) and records it under `branches:`.
7. Append an entry to `{{VAULT_DIR}}/wiki/log.md`:
   `## [YYYY-MM-DD HH:MM] ticket | scaffolded {{TICKET_PREFIX}}-NNNN - <one-line brief>`
8. Report: where the folder is, which files you created and which service pages you updated. Next step: read the affected service code and write `plan.md`.

Follow the conventions in the root schema (frontmatter, wikilinks, ticket structure).
