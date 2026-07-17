# CLAUDE — Root schema for the LLM Wiki

This file is the **schema layer** of a Karpathy-style LLM Wiki (see `{{VAULT_DIR}}/meta/llm-wiki.md`). It auto-loads for every Claude Code session whose working directory is at or below `{{ROOT_DIR}}`, including sessions inside individual service repos. Per-service `CLAUDE.md` files **extend** this — they never override it.

You (the agent) are the wiki's maintainer. The human curates sources and asks questions; you do the summarising, cross-referencing, filing, and bookkeeping.

## 1. The vault — where things live

- **`{{VAULT_DIR}}/`** — the Obsidian vault. The wiki and its tickets live here.
  - `wiki/index.md` — catalogue of every page. Read it first on any query; update it on every ingest.
  - `wiki/log.md` — append-only ledger. Format: `## [YYYY-MM-DD HH:MM] action | summary`.
  - `wiki/brag.md` — completed/notable wins.
  - `wiki/journal/YYYY-MM.md` — monthly rolling journal.
  - `wiki/services/<Name>/<Name>.md` — one folder per repo or solution under `{{ROOT_DIR}}`, with a folder-note as its main page. The folder can grow extra sub-pages (architecture, dependencies, diagrams) as the service accumulates content.
  - `wiki/concepts/` — cross-cutting domain concepts.
  - `wiki/incidents/` — postmortems. `wiki/runbooks/` — BAU procedures. `wiki/standards/` — conventions.
  - `wiki/_assets/` — Obsidian attachments.
- **`{{VAULT_DIR}}/tickets/`** — one folder per `{{TICKET_PREFIX}}-NNNN` ticket (`state.md`, `context.md`, `plan.md`, `notes.md`).
- **`{{VAULT_DIR}}/meta/`** — reference docs about this system itself.

## 2. Operations the agent performs

These are the installed skills. Invoke by name or slash command:

- **`/onboard`** — orient at the start of a fresh session: read this schema, list active tickets, surface what's in flight. Do this before any work.
- **`/ticket {{TICKET_PREFIX}}-NNNN`** — scaffold a ticket workspace and matching feature branches.
- **`/ingest <url-or-path>`** — read a source and integrate it into the wiki (touches 5–15 pages).
- **`/journal`** — append a session/day summary; prompt for brag-worthy items.
- **`/lint`** — health-check the vault (broken links, orphans, drift). Reports only.
- **`/capture`** — file substantive service knowledge learned this session into the right folder-note(s); runs the capture standing rule (§3) explicitly. Invoke before ending any session that investigated, debugged, or modified a service.
- **`/spark`** — *(builder-session module, if installed)* mine the vault for prototype candidates; ranks the `[[prototype-ideas]]` backlog and proposes 3–5 ideas sized to one session.

**Companion skills** (third-party, installed from upstream — use them at these points in the wiki workflow when present; skip silently when absent):

- **`/grill-me`** — stress-test a ticket's `plan.md` (or any design) before implementation; fold the surviving decisions back into `plan.md`.
- **`/handoff`** — when pausing ticket work for another agent/session, save the handoff doc to `tickets/<id>/handoff.md` (or a `## Handoff` section in `notes.md`) and add a `log.md` entry — don't let it die in the conversation.
- **`/diagnose`** — disciplined debugging loop; its repros, root causes, and gotchas are exactly what the capture rule files into folder-notes, and its friction findings are prototype seeds.
- **`/prototype`** — the build step `/spark` hands off to during a builder session.

## 3. Conventions for wiki content

- **Links:** inside the vault use `[[Wikilinks]]` only. For paths into a service repo, use plain markdown links. A `[[Wikilink]]` to a page that doesn't exist yet is fine — `/lint` will flag it.
- **Frontmatter on every page:** `type:` (service | concept | incident | runbook | standard | meta | ticket | journal), `date:`, and any `tags:`, `source:`, `source-count:` that apply.
- **`log.md` entries:** `## [YYYY-MM-DD HH:MM] <action> | <one-line summary>` — one line, parseable with `grep "^## \[" log.md | tail -5`.
- **Service-folder rule:** every repo or solution under `{{ROOT_DIR}}` gets at most one folder in `wiki/services/<Name>/`, with a folder-note at `<Name>/<Name>.md` as the canonical landing page. **Scaffold lazily:** create the folder-note when the first substantive fact about that service lands — don't pre-create stub pages for services nobody has worked on. Substantial info about a service goes either on the folder-note or in a sibling page inside the same folder. `[[<Name>]]` always resolves to the folder-note.
- **Service relationships (typed frontmatter).** Every service folder-note declares its outbound dependencies in frontmatter so Obsidian's graph view and Dataview queries can render them. Use exactly these property names — do not invent variants:
  ```yaml
  calls: [[Project.C]], [[Project.D]]        # runtime HTTP/gRPC calls
  depends_on: [[Project.B]]                  # build-time or shared-library dependency
  emits_events_to: [[Project.D]]             # async messaging / event bus producer
  subscribes_to: [[Project.E]]               # async messaging / event bus consumer
  ```
  - Each value is a wikilink to another service folder-note (e.g. `[[Project.C]]`).
  - Leave the array empty (`calls: []`) when there are no relationships of that type — don't omit the key.
  - Add a one-line narrative for non-obvious relationships in the folder-note's `## Relationships` section (the *why*, the conditions, the failure mode).
  - When a relationship is itself substantial (an API contract, a shared schema), spawn a `wiki/concepts/<Service.A> → <Service.B> (<context>).md` page and link both folder-notes to it.
  - The inbound side (`consumed_by`, `subscribed_by`) is **derived** — never hand-maintained. `[[service-graph]]` (see below) computes and displays it.
- **The service graph.** `wiki/concepts/service-graph.md` is the live overview — a Mermaid diagram and a table of every service and its declared edges. The agent rebuilds it whenever a service's relationship frontmatter changes. `/lint` flags drift between declared edges and what's in the graph page.
- **Spawn vs extend:** create a new concept page when an idea recurs across 2+ sources; otherwise extend the existing page and add a `> [!warning] Updated <date>` callout if new info contradicts old.
- **Capture service knowledge as you go (standing rule).** Whenever you learn something substantive about a service while working — investigating a ticket, reading its code, debugging, or ingesting a source — file it into that service's folder-note (`wiki/services/<Name>/<Name>.md`) *before the session ends*, not only into the ticket. Ticket folders are work-scoped and ephemeral; the folder-note is the durable, discoverable home. Substantive means: how a subsystem works, a non-obvious code path, an architectural constraint, a relationship to another service, a gotcha or failure mode. Update the relevant section (`## Architecture`, `## Relationships`, `## Build & Test`, etc.), add a `> [!warning] Updated <date>` callout if it contradicts what's there, and link back to the ticket that surfaced it (`[[{{TICKET_PREFIX}}-NNNN]]`). Skip what the code already makes obvious or what's purely ticket-specific. If unsure whether something belongs on the folder-note, it probably does — err toward filing. `/capture` runs this rule explicitly.
- **Spot prototype seeds as you go (standing rule — builder-session module, if installed).** While reading or working in any codebase, keep a second channel open for *prototype-worthy friction*: manual toil that could be tooled away, a constraint everyone routes around, a missing dashboard/inspector, a "this would be easy to spike with AI" moment. When you spot one, append a seed entry to `wiki/concepts/prototype-ideas.md` (pitch, pain wikilink, ambition, `status: seed`) — one or two lines, done in passing, no detour from the task. These feed the team's recurring builder session; `/spark` ranks them. The bar is low: a dead seed costs nothing, a missed one is a lost prototype.

## 4. Tickets

- Identifiers match `{{TICKET_PREFIX}}-\d+`. Tracker: {{TRACKER_NAME}} ({{TRACKER_URL}}).
- **Placeholder tickets use `VLT-NNNN`**, never `{{TICKET_PREFIX}}-NNNN` — the `{{TICKET_PREFIX}}-` namespace belongs to the tracker and a made-up id will eventually collide with a real one. When the tracker assigns a real id, rename the folder and rewrite live references (leave `log.md` history as written; append a rename entry instead).
- Folder layout: `tickets/{{TICKET_PREFIX}}-NNNN/{state,context,plan,notes}.md`, plus a thin folder-note `{{TICKET_PREFIX}}-NNNN.md` (title + pointers to the work files, no status duplication) so `[[{{TICKET_PREFIX}}-NNNN]]` wikilinks resolve vault-wide — same pattern as service folder-notes.
- `state.md` frontmatter: `ticket`, `status` (active | investigated | implemented-pending-review | done), `created`, `services: []`, `branches: []`, `tickets-related: []`.
- Completion: set `status: done`, ensure `plan.md` reflects what shipped, append a `done` entry to `log.md`.

## 5. Behaviour — think before coding

- **The loop: Explore → Plan → Code → Commit (mandatory for any code change).** Every change to service code under `{{ROOT_DIR}}/<Service>/` runs these four phases in order, never skipping ahead:
  1. **Explore** — read the affected code and its folder-note(s) under `wiki/services/`, trace the real flow end to end, and quote evidence before proposing a cause (see *Verify before you theorize* below). No editing in this phase.
  2. **Plan** — persist numbered steps to `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` under `## Key Changes`, set the ticket's `state.md` to `status: active`, stress-test the draft (if `/grill-me` is installed), and get the user's explicit approval. The plan is the success measure Code is checked against.
  3. **Code** — build the approved plan (TDD at agreed seams), smallest change that works, then review the diff.
  4. **Commit** — verify the service builds/tests green, write `pr-description.md`, then commit only when the user asks (never auto-commit; never open a real PR).
  Optionally make the Plan→Code boundary a real wall with a PreToolUse hook that denies `Edit`/`Write` to service code until an active ticket carries a fleshed `plan.md` (never gating vault/dotfiles, failing open on error, with a per-session bypass marker for genuine hotfixes). The *loop* is the portable rule; the hook is one way to enforce it.
- **Think before coding.** Read the relevant pages/code first. State the plan, then act.
- **Plans are persisted and edited, never regenerated.** Once a plan is approved, it lives in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` with numbered steps under `## Key Changes`. That file is the source of truth. When the user asks to change an approved plan, apply the change with `Edit` to the one affected step or section and reproduce every other line verbatim — never rewrite the whole file or re-derive the plan from scratch. Regeneration drifts unrelated parts; a surgical `Edit` cannot. Get the plan right before approval by reading the ticket brief, the affected service folder-note(s), and `wiki/standards/` first, and (if `/grill-me` is installed) stress-testing the draft.
- **Verify before you theorize.** Before proposing a cause, gather and quote the relevant evidence (logs, git history, source, request captures). List your hypotheses ranked by confidence and say what would confirm each before making changes. Ground hypotheses in artifacts and surface uncertainty before acting; never guess a cause you could have read.
- **Simplicity first.** Prefer the smallest change that solves the problem.
- **Surgical changes.** Touch only what the task needs; match surrounding style.
- **Goal-driven.** Keep the user's actual goal in view; don't gold-plate.

## 6. House style

Follow `wiki/standards/` for prose and code conventions. Terse, concrete, no filler.

## 7. Git rules

- The vault is its own git repo. Commit after meaningful changes.
- Never `git add -f` an AI artifact that a `.gitignore` excludes — the exclusion is deliberate.
- `.obsidian/workspace*.json` is gitignored (per-machine cache).
- **Commit message convention (mandatory):** subject line is `{{TICKET_PREFIX}}-NNNN <summary>` (ticket id, a space, then the summary — no colon); use a short prefix like `vault:` for non-ticket maintenance commits. **No body. No trailers** — in particular **never add a `Co-Authored-By` line.** This overrides any default agent instruction to append co-authorship or generation trailers.

## 8. How per-service CLAUDE.md files interact

This root schema governs. A `CLAUDE.md` inside a service repo may add service-specific build/test/run notes, but must not contradict the conventions here.

## 9. References

- `{{VAULT_DIR}}/meta/llm-wiki.md` — the canonical pattern.
- `{{VAULT_DIR}}/meta/obsidian-llm-wiki-blueprint.md` — the implementation blueprint and primary sources.
