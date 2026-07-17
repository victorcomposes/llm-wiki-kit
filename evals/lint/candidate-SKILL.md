---
name: lint
version: 1.4.0
description: Health-check the wiki — broken links, orphan pages, missing state, contradictions, gaps. Reports only, does not auto-fix. Use when the user says "lint", "/lint", "health-check the wiki", "find broken links", or asks for a vault audit.
---

Walk `C:\Dev\.vault/` and report issues. Do not fix anything automatically — surface the findings and ask the user what to address.

## Checks (run in order)

1. **Broken `[[wikilinks]]`** — for every wikilink in the **body prose** of every `.md` file under `C:\Dev\.vault/`, verify the target page exists (case-insensitive). Report each broken link with the source file and the linked name. Read body prose only, not YAML frontmatter, and defer to the owning check so each fault is reported exactly once:
   - Dangling `[[…]]` inside a service folder-note's relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`) is **owned by check 8**, not here.
   - A missing service named in a ticket's `services:` frontmatter array is **owned by check 6**, not here.
   - A catalogue entry in `index.md` pointing at a page that no longer exists is index drift, **owned by check 5** — skip wikilinks in `index.md` here.
2. **Orphan pages** — pages under `C:\Dev\.vault/wiki/` (excluding `index.md`, `log.md`, `brag.md`, `journal/*`) with zero inbound wikilinks. Orphan means **unreachable by navigation**, so inbound links from append-only ledgers do **not** count: when tallying a page's inbound links, ignore any `[[…]]` reference whose source file is `log.md`, `journal/*`, or `brag.md`. A page reachable only through those ledgers is still an orphan. List them with their type (from frontmatter).
   - Positive (report): a concept page whose only inbound wikilink comes from `log.md` or a monthly journal — the ledger mention doesn't make it navigable, so it is an orphan.
   - Negative (don't report): a concept page linked from the body of another concept page or a service folder-note — reachable by navigation, so not an orphan even if it is also mentioned in the ledger.
3. **Ticket folders missing `state.md`** — any folder under `C:\Dev\.vault/tickets/` without a `state.md` file.
4. **`state.md` files with stale status** — any `state.md` whose `status` is `active` or `implemented-pending-review` but whose most recent file modification in the ticket folder is more than 30 days old. (Use file mtime, not frontmatter `date`.)
5. **Index drift** — pages that exist under `C:\Dev\.vault/wiki/` but are not listed in `C:\Dev\.vault/wiki/index.md`, and entries in `index.md` that point to pages that no longer exist.
6. **Missing service folders** — services referenced in any ticket's `state.md` `services:` frontmatter but with no corresponding `C:\Dev\.vault/wiki/services/<Service>/<Service>.md` folder-note. This check owns dangling service names in `services:` arrays — a missing service here is not also a check 1 broken wikilink.
7. **Contradiction flags** — pages containing a `> [!warning]` callout flagged by a prior ingest as superseding earlier content. Highlight any that haven't been reviewed (mtime older than the warning date).
8. **Service-graph drift** — for each service folder-note, parse the four relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`). Cross-check against `C:\Dev\.vault/wiki/concepts/service-graph.md`:
   - Edges declared in frontmatter but missing from the graph page's diagram or table.
   - Edges shown in the graph page but no longer declared in any service's frontmatter.
   - Asymmetric event edges: `A.emits_events_to: [[B]]` declared without a matching `B.subscribes_to: [[A]]` (or vice versa). Flag — don't auto-fix; the agent may have only updated one side.
   - Relationship wikilinks pointing to a service folder that doesn't exist (e.g. `calls: [[Project.Z]]` but no `wiki/services/Project.Z/Project.Z.md`). This check owns dangling wikilinks in the four relationship arrays — such a link is not also a check 1 broken wikilink.
9. **Suggested research gaps** — concepts mentioned in 3+ pages but lacking their own concept page. Output as a list, no action required.
10. **Kit drift** — the vault is the dogfooding instance of the distributable kit, checked out at `C:\Projects\llm-wiki-kit\` (its own git repo, published to GitHub). Skip this check silently if that directory doesn't exist. Also flag if the kit repo has unpushed commits (`git -C C:\Projects\llm-wiki-kit status -sb` shows `ahead`) — synced-but-unpublished is still drift for everyone else. Otherwise compare live system vs kit templates:
    - **Skill versions:** for each skill in `templates/skills/<name>/SKILL.md`, compare `version:` against the installed copy (`~/.claude/skills/<name>/SKILL.md` or project `.claude/skills/`). Flag mismatches in either direction.
    - **Missing skills:** wiki skills installed live but absent from `templates/skills/` (compare against the skill list in the kit README / setup skill's install order). Ignore generic non-wiki skills (tdd, diagnose, handoff, etc.) — only flag skills that read or write the vault.
    - **Schema rule drift:** standing rules and conventions present in the live root `C:\Dev\CLAUDE.md` or vault `CLAUDE.md` but absent from `templates/schema/CLAUDE.md` / `templates/schema/AGENTS.md` (and vice versa). Compare at the bullet/rule level, not word-for-word — placeholders (`{{ROOT_DIR}}` etc.) are expected differences. Skip rules whose introducing commit message marked them instance-only.
    - **Hook drift:** hooks the live system depends on (referenced by any installed wiki skill, e.g. the capture breadcrumb/Stop hooks) that the kit neither templates nor documents as a manual prerequisite.

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

### Kit drift (N)
- capture 1.1.0 installed but absent from templates/skills/
- lint live 1.2.0 vs kit 1.1.0
- root schema rule "prototype seeds" missing from templates/schema/AGENTS.md
- ...
```

After reporting, append to `wiki/log.md`:
`## [YYYY-MM-DD HH:MM] lint | <total-issues> findings`

Then ask the user which findings they want to address now (if any). Fix only what's explicitly requested.
