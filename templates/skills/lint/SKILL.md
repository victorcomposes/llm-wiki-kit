---
name: lint
version: 1.2.0
description: Health-check the wiki — broken links, orphan pages, missing state, contradictions, gaps. Reports only, does not auto-fix. Use when the user says "lint", "/lint", "health-check the wiki", "find broken links", or asks for a vault audit.
---

Walk `{{VAULT_DIR}}/` and report issues. Do not fix anything automatically — surface the findings and ask the user what to address.

## Checks (run in order)

1. **Broken `[[wikilinks]]`** — for every wikilink in every `.md` file under `{{VAULT_DIR}}/`, verify the target page exists (case-insensitive). Report each broken link with the source file and the linked name.
2. **Orphan pages** — pages under `{{VAULT_DIR}}/wiki/` (excluding `index.md`, `log.md`, `brag.md`, `journal/*`) with zero inbound wikilinks from anywhere else in the vault. List them with their type (from frontmatter).
3. **Ticket folders missing `state.md`** — any folder under `{{VAULT_DIR}}/tickets/` without a `state.md` file.
4. **`state.md` files with stale status** — any `state.md` whose `status` is `active` or `implemented-pending-review` but whose most recent file modification in the ticket folder is more than 30 days old. (Use file mtime, not frontmatter `date`.)
5. **Index drift** — pages that exist under `{{VAULT_DIR}}/wiki/` but are not listed in `{{VAULT_DIR}}/wiki/index.md`, and entries in `index.md` that point to pages that no longer exist.
6. **Missing service folders** — services referenced in any ticket's `state.md` `services:` frontmatter but with no corresponding `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` folder-note.
7. **Contradiction flags** — pages containing a `> [!warning]` callout flagged by a prior ingest as superseding earlier content. Highlight any that haven't been reviewed (mtime older than the warning date).
8. **Service-graph drift** — for each service folder-note, parse the four relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`). Cross-check against `{{VAULT_DIR}}/wiki/concepts/service-graph.md`:
   - Edges declared in frontmatter but missing from the graph page's diagram or table.
   - Edges shown in the graph page but no longer declared in any service's frontmatter.
   - Asymmetric event edges: `A.emits_events_to: [[B]]` declared without a matching `B.subscribes_to: [[A]]` (or vice versa). Flag — don't auto-fix; the agent may have only updated one side.
   - Relationship wikilinks pointing to a service folder that doesn't exist (e.g. `calls: [[Project.Z]]` but no `wiki/services/Project.Z/Project.Z.md`).
9. **Suggested research gaps** — concepts mentioned in 3+ pages but lacking their own concept page. Output as a list, no action required.
10. **Kit drift** — only applies if this vault is the dogfooding instance of the kit itself (i.e. `{{VAULT_DIR}}/dist/llm-wiki-kit/` exists). Skip silently otherwise. Compare live system vs kit templates:
    - **Skill versions:** for each skill in `templates/skills/<name>/SKILL.md`, compare `version:` against the installed copy. Flag mismatches in either direction.
    - **Missing skills:** wiki skills installed live (skills that read or write the vault) but absent from `templates/skills/`. Ignore generic non-wiki skills.
    - **Schema rule drift:** standing rules/conventions present in the live schema files (root `CLAUDE.md`/`AGENTS.md`, vault `CLAUDE.md`) but absent from `templates/schema/`, or vice versa. Compare at the bullet/rule level — placeholders are expected differences. Skip rules whose introducing commit message marked them instance-only.
    - **Hook drift:** hooks the live system depends on (referenced by any installed wiki skill) that the kit neither templates nor documents as a manual prerequisite.

## Report format

```
## Lint report — <date>

### Broken wikilinks (N)
- wiki/concepts/foo.md → [[missing-page]]
- ...

### Orphan pages (N)
...

### Missing state.md (N)
...

### Stale active tickets (N)
...

### Index drift (N)
...

### Missing service pages (N)
...

### Unreviewed contradiction warnings (N)
...

### Service-graph drift (N)
- Project.A declares calls: [[Project.C]] but service-graph.md shows no such edge
- Project.A.emits_events_to: [[Project.D]] declared without matching Project.D.subscribes_to: [[Project.A]]
- ...

### Suggested concept pages (N)
- "<concept>" referenced in 5 pages but no concept page exists
- ...

### Kit drift (N — only on the kit's dogfooding instance)
- capture 1.1.0 installed but absent from templates/skills/
- lint live 1.2.0 vs kit 1.1.0
- schema rule "prototype seeds" missing from templates/schema/AGENTS.md
- ...
```

After reporting, append to `wiki/log.md`:
`## [YYYY-MM-DD HH:MM] lint | <total-issues> findings`

Then ask the user which findings they want to address now (if any). Fix only what's explicitly requested.
