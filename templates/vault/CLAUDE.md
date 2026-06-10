# CLAUDE — Vault-local schema

This file auto-loads for any agent session whose working directory is inside `{{VAULT_DIR}}` (e.g. an agent opened directly on the vault rather than on `{{ROOT_DIR}}`). It's a **focused** schema: only the rules that matter when you're editing wiki content. The full constitution is at `{{ROOT_DIR}}/CLAUDE.md` and still governs — this file extends, never overrides it.

## You are inside the vault

The vault root is `{{VAULT_DIR}}`. Everything you write under it falls into one of:

- `wiki/index.md` — catalogue of every page. Update on every page add/rename.
- `wiki/log.md` — append-only ledger. Never edit existing lines.
- `wiki/brag.md` — completed/notable wins. Append-only by convention.
- `wiki/journal/YYYY-MM.md` — monthly rolling journal.
- `wiki/services/<Name>/<Name>.md` — one folder per repo or solution under `{{ROOT_DIR}}`. The `<Name>.md` inside is the canonical folder-note (so `[[<Name>]]` resolves to it). Add sub-pages inside the folder as the service grows.
- `wiki/concepts/` — cross-cutting domain concepts.
- `wiki/incidents/` — postmortems.
- `wiki/runbooks/` — BAU procedures.
- `wiki/standards/` — house conventions for prose and code.
- `wiki/_assets/` — Obsidian attachments (images, pdfs).
- `tickets/{{TICKET_PREFIX}}-NNNN/` — one folder per ticket.

If a write doesn't fit any of those, stop and ask the user where it belongs.

## Conventions inside the vault

- **Wikilinks only** between vault pages: `[[Page Name]]`. Never use markdown links for in-vault references.
- **Plain markdown** for links from a vault page out to a service repo (e.g. `[Orchestrator README](../../../Orchestrator/README.md)`).
- **Frontmatter on every page**, minimum:
  ```yaml
  ---
  type: <concept|incident|runbook|service|ticket|standard|meta|journal>
  date: YYYY-MM-DD
  tags: []
  ---
  ```
  Service folder-notes also carry `service:` and the four relationship properties — `calls: []`, `depends_on: []`, `emits_events_to: []`, `subscribes_to: []` — each an array of `[[Service]]` wikilinks (empty when none; never omit the key). Ticket pages also carry `ticket:`, `status:`, `services:`, `branches:`.
- **Service graph.** `wiki/concepts/service-graph.md` is the rolled-up view of all service relationships (Mermaid + table). Rebuild it after any change to service relationship frontmatter — don't let it drift.
- **`log.md` entry format**: `## [YYYY-MM-DD HH:MM] <op> | <one-line summary>` where `<op>` ∈ {`session`, `ingest`, `ticket`, `journal`, `lint`, `brag`, `bootstrap`, `update`, `graph`, `page`, `spark`}.
- **Updates vs spawns**: extend the existing page when an idea recurs. Spawn a new concept page only when something genuinely doesn't fit anywhere.
- **Contradictions**: if new info conflicts with an existing page, add a `> [!warning] Updated YYYY-MM-DD` callout above the affected section — don't silently rewrite history.
- **Prototype seeds (standing rule — builder-session module, if installed)**: whenever you file a gotcha, failure mode, pain point, or a "we'd never get runway for this" moment anywhere in the vault, ask "could this be prototyped in one builder session?" If yes, append a seed entry to `wiki/concepts/prototype-ideas.md` (pitch, pain wikilink, ambition, `status: seed`). `/spark` ranks the backlog before each session.

## Don't do these things inside the vault

- Don't hand-edit `wiki/` pages without a reason; `/ingest` is the normal write path.
- Don't break the `log.md` append-only rule. If you must correct an entry, append a correction below — never edit in place.
- Don't write absolute paths into wiki content. Use wikilinks or paths relative to `{{VAULT_DIR}}`.
- Don't commit `.obsidian/workspace*.json` (gitignored — it's per-machine cache).

## When in doubt

Read the root schema at `{{ROOT_DIR}}/CLAUDE.md` and `{{VAULT_DIR}}/meta/llm-wiki.md` for the upstream pattern. The house style is `{{VAULT_DIR}}/wiki/standards/` — defer to whatever is documented there.
