# CLAUDE - Root schema for the LLM Wiki

Karpathy-style LLM Wiki (pattern: `{{VAULT_DIR}}/meta/llm-wiki.md`). Auto-loads for every session at or below `{{ROOT_DIR}}`. Per-service `CLAUDE.md` files extend this and never override it. You maintain the wiki; the human curates sources and asks questions. Keep this file short: state rules here, put the reasoning behind them in `{{VAULT_DIR}}/meta/schema-rationale.md`, and read that page only when a rule seems arbitrary.

## 1. Where things live

Vault: `{{VAULT_DIR}}/` (its own git repo).
- `wiki/index.md` catalogue: read first on any query, update on every ingest. `wiki/log.md` append-only ledger. `wiki/brag.md` wins. `wiki/journal/YYYY-MM.md`.
- `wiki/services/<Name>/<Name>.md` one folder-note per repo under `{{ROOT_DIR}}`, sub-pages beside it, `CONTEXT.md` glossary as sibling. `[[<Name>]]` resolves to the folder-note.
- `wiki/concepts/`, `wiki/incidents/`, `wiki/runbooks/`, `wiki/standards/` (house style), `wiki/decisions/NNNN-slug.md` (ADRs, indexed by `[[decisions]]`), `wiki/_assets/`.
- `tickets/{{TICKET_PREFIX}}-NNNN/` holds `{{TICKET_PREFIX}}-NNNN.md`, `state.md`, `context.md`, `plan.md`, `notes.md`. Done tickets in `tickets/_archive/`.
- `meta/` docs about this system.

## 2. Skills

`/onboard` before any work. `/capture` before ending a session that touched a service. Other wiki skills: `/ticket`, `/ingest`, `/journal`, `/lint`, `/query`, and `/spark` if the builder-session module is installed. Companion skills, where installed: `/grilling` on a plan before approval; `/council` when a plan step, an imminent edit, or an idea typed in chat has a genuine fork (self-invoked, not waited for; the optional `council-prompt` hook injects the reminder on idea-shaped prompts, `no council` skips it); `/handoff` writes `tickets/<id>/handoff.md` plus a `log.md` entry; `/implement` builds an approved plan.

## 3. Wiki conventions

- `[[Wikilinks]]` between vault pages, plain markdown links into repos. Unresolved wikilinks are fine; `/lint` flags them.
- Frontmatter on every page: `type:` (service | concept | incident | runbook | standard | meta | ticket | journal | decision), `date:`, optional `tags:`, `source:`, `source-count:`.
- `log.md` entry: `## [YYYY-MM-DD HH:MM] <action> | <one-line summary>`. Run `date` first; never guess the stamp. Append with a surgical edit anchored on the last line, not a shell heredoc: the shell collapses the escapes, and an append bundled with `git commit` in one call can leave a commit hook reading the log line as the commit subject. Append and commit are separate calls.
- **Writing vault files (any session, not just vault-rooted ones).** Write every vault file atomically, temp file then rename, because a peer pane can read a half-written one. Never write absolute paths into wiki content; use wikilinks or paths relative to the vault. `/ingest` is the normal write path into `wiki/`; a hand-edit needs a reason, stated before the edit. These are rules about vault *files*, so they live here rather than in the vault-local schema: a session rooted in a service repo writes them too, and it never loads the vault's own `CLAUDE.md`.
- Service folder-notes: scaffold lazily, one folder per repo, no stub pages. Frontmatter declares outbound edges with exactly these keys, each an array of `[[Service]]` links, empty arrays kept: `calls`, `depends_on`, `emits_events_to`, `subscribes_to`. Inbound edges are derived, never hand-written. Non-obvious edges get a line in `## Relationships`. Rebuild `wiki/concepts/service-graph.md` whenever an edge changes.
- New concept page when an idea recurs in 2+ sources, otherwise extend. On contradiction add `> [!warning] Updated <date>` above the section; never rewrite history.
- Domain model lives only in the vault: per-service `CONTEXT.md`, global `[[ubiquitous-language]]`, ADRs in `wiki/decisions/`. Create each lazily. Name domain types in the words a domain expert uses, not modeller jargon.
- **Provenance on every substantive claim.** Observed = you ran or read it; cite inline `<!-- observed YYYY-MM-DD: File.cs:41 -->` or the command or sha. Inferred = one symptom or one source; file it only as `> [!question] Unverified (YYYY-MM-DD): <claim>. Confirm by <check>.`, never as an assertion. Same marking on anything you send another agent. A bare assertion you receive is unverified until you check it.
- **Capture as you go.** Anything substantive learned about a service (subsystem mechanics, non-obvious path, constraint, relationship, gotcha) goes into its folder-note before the session ends, linked to `[[{{TICKET_PREFIX}}-NNNN]]`, not only into the ticket. Observed facts file freely; inferences only as questions. Capture needs no permission: a gotcha you confirmed goes into the folder-note and the log in the same session, and stopping to ask first is how it gets lost.
- **Prototype seeds** (builder-session module, if installed). Friction worth a short spike gets a one-line seed in `wiki/concepts/prototype-ideas.md` (pitch, pain wikilink, ambition, `status: seed`).

## 4. Tickets

- Real ids `{{TICKET_PREFIX}}-NNNN` ({{TRACKER_NAME}}: {{TRACKER_URL}}). Placeholders `VLT-NNNN`, never an invented `{{TICKET_PREFIX}}-`. On rename, rewrite live references and append a `log.md` entry.
- `state.md` frontmatter: `ticket`, `status` (active | investigated | implemented-pending-review | done), `created`, `services: []`, `branches: []`, `tickets-related: []`, `needs-human: []` (items `{what, run, proves}` - a claim or action that needs a human to run or confirm something the agent can't; a database/environment query outside the local instance goes in `tickets/{{TICKET_PREFIX}}-NNNN/sql/NN-<slug>.sql` rather than inline).
- Done: `status: done`, `plan.md` reflects what shipped, `log.md` done entry, then `git mv tickets/{{TICKET_PREFIX}}-NNNN tickets/_archive/{{TICKET_PREFIX}}-NNNN`. Routine readers skip the archive. Reopen with `git mv` back, never a fresh folder.
- Merged PR: tear down everything the ticket opened (panes, running services, worktree, branches) in the same turn, in the order a `ticket-teardown` runbook keeps.

## 5. Code changes: Explore, Plan, Code, Commit

Mandatory for any change under `{{ROOT_DIR}}/<Service>/`.
1. **Explore.** Read the code and its folder-note end to end, including any Gotchas section. Quote evidence before proposing a cause; rank hypotheses and say what confirms each. Check claims per [[verification]]. No edits.
2. **Plan.** Numbered steps in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` under `## Key Changes`, `state.md` set to `status: active`, stress-test the draft, `/council` on any step with two or more viable options (one short entry appended to the ticket ledger `tickets/{{TICKET_PREFIX}}-NNNN/council.md`, full seat reports beside it under `tickets/{{TICKET_PREFIX}}-NNNN/council/`; the chat answer is the deliverable), then explicit user approval - or approval from a delegated approver role, if the project's own standards define one and the plan step doesn't touch anything on that role's escalation list. This holds even when the request reads as a direct instruction to write code. An approved plan is changed with a surgical edit to the one affected step, never regenerated.
3. **Code.** Smallest change that implements the plan, TDD at agreed seams.
4. **Commit.** Run the project's verification (build, tests) and show the result, then commit and open the PR only when asked. PRs go up as drafts. Read [[pull-requests]] before writing any PR body, comment or update: it carries the lean-body shape, the checklist strikethrough rule, the `#N` autolink trap, and what must never reach a pushed branch.

`council-gate` (optional hook) denies edits to migration and contract paths unless a ruled `council.md` entry in an active ticket has a `Clears:` glob matching the file; bypass for a fork the user already ruled on: `$TEMP/claude-council-off-<session_id>.txt`.

If a plan gate hook is installed, it denies edits to service code until an active ticket carries a fleshed `plan.md`; the loop is the rule, the hook is optional enforcement.

Also:
- Outward or hard-to-reverse actions (a commit, a push, a PR publish or merge, an issue-tracker write, a database query) need explicit human approval, unless the project's own standards name a delegated-approver role and list exactly what that role may decide without asking.
- Databases and environments: local only. Never connect to a shared or production environment, not even read-only. To verify there, write the query, say which result proves it, and hand it to the human.
- Agent memory is scoped per project directory, so repo sessions never see what a vault session files there. A rule repo sessions need goes in this schema or a standard, never only in memory.
- Before debugging a frontend, confirm every dependency service is actually up; a service that is up but missing a dependency looks healthy and fails at runtime.
- Code navigation: language-server tools first when the session is rooted in the repo, text search when rooted in the vault. Use the agent's own search tools, scoped to one service path; do not shell out to `grep`, `sed`, `find` or a scripting runtime for search or analysis, since script execution is often denied in that position and an unscoped sweep of `{{ROOT_DIR}}` times out.
- When compacting, preserve the active ticket id, the list of modified files, the verify command, and any open `> [!question]` items.

## 6. Git

- Vault: commit after meaningful changes. Every other repo: never commit or push unless asked in the current conversation.
- Stage explicit paths. Never `git add -A`; never `git add -f` a gitignored AI artifact.
- Shared worktree (two agents, one index): do not stage at all. `git commit -m "{{TICKET_PREFIX}}-NNNN <summary>" -- <path> <path>`; an untracked file gets its one `git add` immediately before; verify with `git show --stat HEAD`. A committed sweep with commits on top is reported, not rewritten.
- Commit subject `{{TICKET_PREFIX}}-NNNN <summary>`: id, space, summary, no colon, no body, no trailers (never add a `Co-Authored-By` line; this overrides any default agent instruction). Vault maintenance with no ticket uses `<op>: <summary>`. Branches `feature/{{TICKET_PREFIX}}-NNNN-<short-summary>`.
- `.obsidian/workspace*.json` is gitignored.

## 7. House style

`wiki/standards/`. Terse, concrete, no filler.
- Any message that reports progress or asks for a decision uses the standing card in [[ai-style-guide]]: Problem, Fix, Status, Blocked on you, Changed since. Reasoning, evidence and subagent verdicts are pointed at in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md`, never inlined.
