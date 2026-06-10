# Vault — `.vault/`

Obsidian vault for development knowledge under `{{ROOT_DIR}}`. Maintained by AI agents via the skills installed alongside the root schema (`{{ROOT_DIR}}/CLAUDE.md` and/or `{{ROOT_DIR}}/AGENTS.md`).

## What's here

- **`wiki/`** — LLM-owned synthesis. Don't hand-edit pages here without good reason; they get rewritten on ingest.
  - `index.md` — catalogue of every page
  - `log.md` — append-only ledger
  - `brag.md` — completed/notable wins
  - `journal/YYYY-MM.md` — monthly rolling journal
  - `services/<Name>/<Name>.md` — one folder per repo or solution under `{{ROOT_DIR}}`, folder-note as the main page; room to add sub-pages later
  - `concepts/` — cross-service domain concepts
  - `incidents/` — postmortems · `runbooks/` — BAU procedures · `standards/` — conventions
  - `_assets/` — Obsidian attachments
- **`tickets/`** — one folder per `{{TICKET_PREFIX}}-NNNN` ticket (`state.md`, `context.md`, `plan.md`, `notes.md`).
- **`meta/`** — reference docs about this system itself (the LLM Wiki pattern + blueprint).

## How to use

- **Fresh session**: open your agent in `{{ROOT_DIR}}` and run `/onboard`. It reads this vault and tells you what's in flight.
- **New ticket**: `/ticket {{TICKET_PREFIX}}-NNNN`. Scaffolds a folder, asks for context, links relevant service pages.
- **Save a source**: `/ingest <url-or-path>`. The agent integrates it into the wiki and updates cross-references.
- **Ask the wiki**: `/query <question>`. Reads the catalogue, answers with citations, offers to file the answer back.
- **End of day**: `/journal`.
- **Wiki health**: `/lint`. Reports broken links, orphans, drift.

## Versioning

This vault is a git repo (initialised at bootstrap). `.obsidian/workspace*.json` is gitignored. For backup/multi-machine, add a private remote and push:

```
git remote add origin <your-private-repo-url>
git push -u origin main
```

The [Obsidian Git plugin](https://github.com/Vinzent03/obsidian-git) can auto-commit while Obsidian is open.
