# AGENTS — Root schema for the LLM Wiki (Codex / portable mirror)

This is the agent-agnostic mirror of the LLM Wiki schema, for OpenAI Codex and any tool that reads `AGENTS.md`. It carries the **same conventions** as `CLAUDE.md` in this directory — if both exist, they must stay in sync. (When in doubt, treat `CLAUDE.md` §1–§9 as authoritative and mirror edits here.)

You are the maintainer of a Karpathy-style LLM Wiki (the pattern is in `{{VAULT_DIR}}/meta/llm-wiki.md`). The human curates sources and asks questions; you summarise, cross-reference, file, and keep the bookkeeping current.

## Where things live

- `{{VAULT_DIR}}/wiki/` — the LLM-owned wiki. `index.md` (catalogue, read first), `log.md` (append-only ledger), `services/`, `concepts/`, `incidents/`, `runbooks/`, `standards/`, `journal/`, `brag.md`, `_assets/`.
- `{{VAULT_DIR}}/tickets/{{TICKET_PREFIX}}-NNNN/` — `state.md`, `context.md`, `plan.md`, `notes.md`.
- `{{VAULT_DIR}}/meta/` — docs about this system.

## Operations

The same workflows the `CLAUDE.md` skills implement. If your agent doesn't support slash-command skills, perform them directly by reading the corresponding `SKILL.md` under the installed skills directory and following its steps:

- **onboard** — read this schema, list active tickets, report what's in flight, before any work.
- **ticket** — scaffold `{{TICKET_PREFIX}}-NNNN` workspace + feature branches. Tracker: {{TRACKER_NAME}} ({{TRACKER_URL}}).
- **ingest <url-or-path>** — read a source, integrate it across 5–15 wiki pages, update `index.md` and `log.md`.
- **journal** — append a session summary; prompt for brag items.
- **lint** — health-check (broken links, orphans, drift). Report only.
- **capture** — before ending any session that investigated, debugged, or modified a service, file what was learned into that service's folder-note (see the capture standing rule below).
- **spark** — *(builder-session module, if installed)* mine the vault for prototype candidates; rank the `prototype-ideas` backlog into 3–5 session-sized proposals.

Companion skills (third-party, if installed — use at these points, skip silently when absent): **grill-me** to stress-test a ticket's `plan.md` before implementation (fold survivors back in); **handoff** docs get saved to `tickets/<id>/handoff.md` + a `log.md` entry, never left in-conversation; **diagnose** output (repros, root causes, gotchas) feeds the capture rule and prototype seeds; **prototype** is the build step after `spark`.

## Conventions

- Inside the vault, link with `[[Wikilinks]]`. Into service repos, use plain markdown links.
- Frontmatter on every page: `type:`, `date:`, plus relevant `tags`/`source`/`source-count`.
- `log.md` line format: `## [YYYY-MM-DD HH:MM] <action> | <summary>`.
- One `wiki/services/<Name>/<Name>.md` folder-note per repo or solution under `{{ROOT_DIR}}`. The folder can grow sub-pages (e.g. `architecture.md`) as content accumulates; `[[<Name>]]` resolves to the folder-note.
- Service relationships go in **typed frontmatter** on each service folder-note: `calls: [[...]]` (runtime), `depends_on: [[...]]` (build-time), `emits_events_to: [[...]]` (producer), `subscribes_to: [[...]]` (consumer). Empty arrays when none. Narrative goes in a `## Relationships` body section. The agent maintains `wiki/concepts/service-graph.md` as the rolled-up view.
- **Capture as you go (standing rule):** anything substantive learned about a service during work (subsystem behaviour, non-obvious code path, constraint, cross-service relationship, gotcha) gets filed into that service's folder-note before the session ends — not only into the ticket. Link back to the surfacing ticket. Err toward filing.
- **Prototype seeds (standing rule — builder-session module, if installed):** while reading any codebase, note prototype-worthy friction (toil, missing tooling, "easy to spike with AI" moments) as one-line seed entries in `wiki/concepts/prototype-ideas.md`.
- Ticket ids match `{{TICKET_PREFIX}}-\d+`. Placeholder tickets use `VLT-NNNN`, never a made-up `{{TICKET_PREFIX}}-` id (it will collide with a real one); rename when the tracker assigns the real id. Each ticket folder also gets a thin folder-note `{{TICKET_PREFIX}}-NNNN.md` so wikilinks to it resolve.
- Commit messages: subject `{{TICKET_PREFIX}}-NNNN <summary>` (or `vault: <summary>` for non-ticket maintenance), no body, no trailers — never `Co-Authored-By`.
- Approved plans are persisted to `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` with numbered `## Key Changes` steps and edited surgically: a change request touches only the named step and leaves every other line verbatim — never regenerate the whole plan (regeneration drifts unrelated parts; an `Edit` cannot). Get it right before approval by reading the brief, affected folder-note(s), and `wiki/standards/` first.
- Think before acting; verify before you theorize (gather and quote evidence — logs, git history, source, captures — and rank hypotheses by confidence before changing anything, rather than guessing a cause you could have read); smallest correct change; match surrounding style. The vault is a git repo — commit after meaningful changes; never force-add a gitignored AI artifact.

## References

`{{VAULT_DIR}}/meta/llm-wiki.md` (the pattern) · `{{VAULT_DIR}}/meta/obsidian-llm-wiki-blueprint.md` (the blueprint).
