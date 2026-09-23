---
name: lint
version: 1.7.0
description: Health-check the wiki — broken links, orphan pages, missing state, contradictions, gaps. Reports only, does not auto-fix. Use when the user says "lint", "/lint", "health-check the wiki", "find broken links", or asks for a vault audit.
---

Walk `{{VAULT_DIR}}/` and report issues. Do not fix anything automatically — surface the findings and ask the user what to address.

**The ticket folders inside `tickets/_archive/` are out of scope as _sources_.** Completed tickets are frozen — never lint their contents, and never report findings inside them. They remain valid _targets_: a `[[{{TICKET_PREFIX}}-NNNN]]` resolving into `_archive/` is correct, not a broken link (check 1). The archive's own index, `tickets/_archive/_archive.md`, **is** still linted — it is a live catalogue page, and drift there matters.

## Checks (run in order)

1. **Broken `[[wikilinks]]`** — for every wikilink in the **body prose** of every `.md` file under `{{VAULT_DIR}}/`, verify the target page exists (case-insensitive). Report each broken link with the source file and the linked name. Read body prose only, not YAML frontmatter, and defer to the owning check so each fault is reported exactly once:
   - Dangling `[[…]]` inside a service folder-note's relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`) is **owned by check 8**, not here.
   - A missing service named in a ticket's `services:` frontmatter array is **owned by check 6**, not here.
   - A catalogue entry in `index.md` pointing at a page that no longer exists is index drift, **owned by check 5** — skip wikilinks in `index.md` here.
   - A ticket-id link (`[[{{TICKET_PREFIX}}-NNNN]]`, `[[VLT-NNNN]]`) resolves when `tickets/<id>/` or `tickets/_archive/<id>/` exists, even without an `<id>.md` note inside. Only an id with no folder in either place is broken. The same rule applies to index entries in check 5.
2. **Orphan pages** — pages under `{{VAULT_DIR}}/wiki/` (excluding `index.md`, `log.md`, `brag.md`, `journal/*`) with zero inbound wikilinks. Orphan means **unreachable by navigation**, so inbound links from append-only ledgers do **not** count: when tallying a page's inbound links, ignore any `[[…]]` reference whose source file is `log.md`, `journal/*`, or `brag.md`. A page reachable only through those ledgers is still an orphan. List them with their type (from frontmatter).
   - Positive (report): a concept page whose only inbound wikilink comes from `log.md` or a monthly journal — the ledger mention doesn't make it navigable, so it is an orphan.
   - Negative (don't report): a concept page linked from the body of another concept page or a service folder-note — reachable by navigation, so not an orphan even if it is also mentioned in the ledger.
3. **Ticket folders missing `state.md`** — any folder *directly* under `{{VAULT_DIR}}/tickets/`, excluding `_archive/` itself, without a `state.md` file.
4. **`state.md` files with stale status** — any `state.md` whose `status` is `active` or `implemented-pending-review` but whose most recent file modification in the ticket folder is more than 30 days old. (Use file mtime, not frontmatter `date`.)
5. **Index drift** — pages that exist under `{{VAULT_DIR}}/wiki/` but are not listed in `{{VAULT_DIR}}/wiki/index.md`, and entries in `index.md` that point to pages that no longer exist.
6. **Missing service folders** — services referenced in any ticket's `state.md` `services:` frontmatter but with no corresponding `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` folder-note. This check owns dangling service names in `services:` arrays — a missing service here is not also a check 1 broken wikilink.
7. **Contradiction flags** — pages containing a `> [!warning]` callout flagged by a prior ingest as superseding earlier content. Highlight any that haven't been reviewed (mtime older than the warning date).
8. **Service-graph drift** — for each service folder-note, parse the four relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`). Cross-check against `{{VAULT_DIR}}/wiki/concepts/service-graph.md`:
   - Edges declared in frontmatter but missing from the graph page's diagram or table.
   - Edges shown in the graph page but no longer declared in any service's frontmatter.
   - Asymmetric event edges: `A.emits_events_to: [[B]]` declared without a matching `B.subscribes_to: [[A]]` (or vice versa). Flag — don't auto-fix; the agent may have only updated one side.
   - Relationship wikilinks pointing to a service folder that doesn't exist (e.g. `calls: [[Project.Z]]` but no `wiki/services/Project.Z/Project.Z.md`). This check owns dangling wikilinks in the four relationship arrays — such a link is not also a check 1 broken wikilink.
9. **Suggested research gaps** — concepts mentioned in 3+ pages but lacking their own concept page. Output as a list, no action required.
10. **Kit drift** — only applies if this vault is the dogfooding instance of the kit itself (i.e. a checkout of the `llm-wiki-kit` repo exists under `{{ROOT_DIR}}`). Skip silently otherwise. Compare live system vs kit templates, and also flag if the kit checkout has unpushed commits — synced-but-unpublished is still drift for everyone else:
    - **Skill versions:** for each skill in `templates/skills/<name>/SKILL.md`, compare `version:` against the installed copy. Flag mismatches in either direction.
    - **Missing skills:** wiki skills installed live (skills that read or write the vault) but absent from `templates/skills/`. Ignore generic non-wiki skills.
    - **Schema rule drift:** standing rules/conventions present in the live schema files (root `CLAUDE.md`/`AGENTS.md`, vault `CLAUDE.md`) but absent from `templates/schema/`, or vice versa. Compare at the bullet/rule level — placeholders are expected differences. Skip rules whose introducing commit message marked them instance-only.
    - **Hook drift:** hooks the live system depends on (referenced by any installed wiki skill) that the kit neither templates nor documents as a manual prerequisite.

11. **Claim drift** - folder-note and concept-page claims about code that are no longer true. This check catches what no writing rule can prevent: a page that was correct when written, describing code that has since moved. Scope: `wiki/services/**`, `wiki/concepts/**`, `wiki/decisions/**`, `wiki/runbooks/**`, `wiki/standards/**`. **Runbooks rank first** - they are procedures someone executes, so a stale command costs an hour of someone's setup, not just a wrong belief. For every claim carrying a code reference (a `File.cs:NN`, a type or method name, a path under `{{ROOT_DIR}}/<Service>/`, or an `<!-- observed ... -->` marker):
    - **Does the target still exist?** Resolve the path or symbol. Missing file, renamed type, dead path = `GONE`. Mechanical - cheap model.
    - **Does it still say what the page claims?** Read the cited lines and compare them against the assertion. Mismatch = `STALE`. Include the commit that moved it (`git log -1 --format='%h %ad %s' -- <path>`) so the drift window is visible. Judgement - use a strong model.
    - **Unmarked claims** - a substantive assertion about code with no provenance marker at all. Report as `UNMARKED`. These predate the provenance rule and cannot be audited without re-reading the code; they are the backlog, not a failure.
    A `> [!question]` block is **not** drift. An unverified claim correctly marked unverified is the system working as designed.

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

### Claim drift (N)
- GONE     wiki/services/Foo/Foo.md:88 -> cites `Bar.cs:41`, file no longer exists
- STALE    wiki/services/Foo/Foo.md:102 -> claims X; changed by 8198f377 2026-07-23
- UNMARKED wiki/concepts/bar.md:15 -> asserts code behaviour, no provenance marker
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
