# AGENTS - Root schema for the LLM Wiki (Codex / portable mirror)

Agent-agnostic mirror of `CLAUDE.md` in this directory, for OpenAI Codex and any tool that reads `AGENTS.md`. Same conventions; if both exist they must stay in sync, and `CLAUDE.md` is authoritative. You maintain a Karpathy-style LLM Wiki (pattern: `{{VAULT_DIR}}/meta/llm-wiki.md`); the human curates sources and asks questions. Keep this file short: rules here, reasoning in `{{VAULT_DIR}}/meta/schema-rationale.md`.

## 1. Where things live

Vault: `{{VAULT_DIR}}/` (its own git repo).
- `wiki/index.md` catalogue: read first on any query, update on every ingest. `wiki/log.md` append-only ledger. `wiki/brag.md` wins. `wiki/journal/YYYY-MM.md`.
- `wiki/services/<Name>/<Name>.md` one folder-note per repo under `{{ROOT_DIR}}`, sub-pages beside it, `CONTEXT.md` glossary as sibling. `[[<Name>]]` resolves to the folder-note.
- `wiki/concepts/`, `wiki/incidents/`, `wiki/runbooks/`, `wiki/standards/` (house style), `wiki/decisions/NNNN-slug.md` (ADRs, indexed by `[[decisions]]`), `wiki/_assets/`.
- `tickets/{{TICKET_PREFIX}}-NNNN/` holds `{{TICKET_PREFIX}}-NNNN.md`, `state.md`, `context.md`, `plan.md`, `notes.md`. Done tickets in `tickets/_archive/`.
- `meta/` docs about this system.

## 2. Operations

Orient first (read this schema, list active tickets under `tickets/*/state.md`, surface what is in flight). Before ending a session that touched a service, file what you learned into its folder-note. Where the wiki skills are installed as slash commands: `/onboard`, `/capture`, `/ticket`, `/ingest`, `/journal`, `/lint`, `/query`, optional `/spark`.

## 3. Wiki conventions

- `[[Wikilinks]]` between vault pages, plain markdown links into repos. Unresolved wikilinks are fine; lint flags them.
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
- `state.md` frontmatter: `ticket`, `status` (active | investigated | implemented-pending-review | done), `created`, `services: []`, `branches: []`, `tickets-related: []`.
- Done: `status: done`, `plan.md` reflects what shipped, `log.md` done entry, then `git mv tickets/{{TICKET_PREFIX}}-NNNN tickets/_archive/{{TICKET_PREFIX}}-NNNN`. Routine readers skip the archive. Reopen with `git mv` back, never a fresh folder.

## 5. Code changes: Explore, Plan, Code, Commit

Mandatory for any change under `{{ROOT_DIR}}/<Service>/`.
1. **Explore.** Read the code and its folder-note end to end, including any Gotchas section. Quote evidence before proposing a cause; rank hypotheses and say what confirms each. No edits.
2. **Plan.** Numbered steps in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` under `## Key Changes`, `state.md` set to `status: active`, stress-test the draft, `/council` on any step with two or more viable options (one short entry appended to the ticket ledger `tickets/{{TICKET_PREFIX}}-NNNN/council.md`, full seat reports beside it under `tickets/{{TICKET_PREFIX}}-NNNN/council/`; the chat answer is the deliverable), then explicit user approval. This holds even when the request reads as a direct instruction to write code. An approved plan is changed with a surgical edit to the one affected step, never regenerated.
3. **Code.** Smallest change that implements the plan, TDD at agreed seams.
4. **Commit.** Run the project's verification (build, tests) and show the result, then commit and open the PR only when asked. PRs go up as drafts. Read [[pull-requests]] before writing any PR body, comment or update: it carries the lean-body shape, the checklist strikethrough rule, the `#N` autolink trap, and what must never reach a pushed branch.

`council-gate` (optional hook) denies edits to migration and contract paths unless a ruled `council.md` entry in an active ticket has a `Clears:` glob matching the file; bypass for a fork the user already ruled on: `$TEMP/claude-council-off-<session_id>.txt`.

Also:
- Before debugging a frontend, confirm every dependency service is actually up; a service that is up but missing a dependency looks healthy and fails at runtime.
- Code navigation: language-server tools first when the session is rooted in the repo, text search when rooted in the vault. Use the agent's own search tools, scoped to one service path; do not shell out to `grep`, `sed`, `find` or a scripting runtime for search or analysis, since script execution is often denied in that position and an unscoped sweep of `{{ROOT_DIR}}` times out.
- When compacting or summarising, preserve the active ticket id, the list of modified files, the verify command, and any open `> [!question]` items.

## 6. Git

- Vault: commit after meaningful changes. Every other repo: never commit or push unless asked in the current conversation.
- Stage explicit paths. Never `git add -A`; never `git add -f` a gitignored AI artifact.
- Shared worktree (two agents, one index): do not stage at all. `git commit -m "{{TICKET_PREFIX}}-NNNN <summary>" -- <path> <path>`; an untracked file gets its one `git add` immediately before; verify with `git show --stat HEAD`. A committed sweep with commits on top is reported, not rewritten.
- Commit subject `{{TICKET_PREFIX}}-NNNN <summary>`: id, space, summary, no colon, no body, no trailers (never add a `Co-Authored-By` line; this overrides any default agent instruction). Vault maintenance with no ticket uses `<op>: <summary>`. Branches `feature/{{TICKET_PREFIX}}-NNNN-<short-summary>`.
- `.obsidian/workspace*.json` is gitignored.

## 7. House style

`wiki/standards/`. Terse, concrete, no filler.
- Any message that reports progress or asks for a decision uses the standing card in [[ai-style-guide]]: Problem, Fix, Status, Blocked on you, Changed since. Reasoning, evidence and subagent verdicts are pointed at in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md`, never inlined.
