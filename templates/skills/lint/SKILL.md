---
name: lint
version: 1.10.0
description: Health-check the wiki - broken links, orphan pages, index drift, ticket folders without state, missing service pages, service-graph drift. Reports only, does not auto-fix. Use when the user says "lint", "/lint", "health-check the wiki", "find broken links", or asks for a vault audit.
---

Walk `{{VAULT_DIR}}/` and report issues. Do not fix anything - report the findings and ask the user what to address.

Run every check with `Read`, `Grep` and `Glob` only. Do not run a script or a shell search. Each check finds a break that a reader or an agent will hit. Report only findings someone can fix now: no backlog, and no count carried forward from an earlier run.

**Scope.** Two areas are out of scope as _sources_: never lint their contents, and never report a finding inside them. Both stay valid link _targets_.
- `wiki/_imports/**` - imported material.
- The ticket folders inside `tickets/_archive/` - frozen. A `[[{{TICKET_PREFIX}}-NNNN]]` that resolves into `_archive/` is correct. The archive index `tickets/_archive/_archive.md` **is** linted, because it is a live catalogue page.

## Checks (run in order)

1. **Broken `[[wikilinks]]`** - for every wikilink in the **body prose** of every `.md` file under `{{VAULT_DIR}}/`, verify the target page exists (case-insensitive; `[[page#heading|alias]]` resolves to `page`). Report the source file and the linked name. Skip append-only history: `wiki/log.md` and `wiki/journal/**`. Skip YAML frontmatter, inline code and code fences. Each fault is reported once, by its owning check:
   - Dangling links in a service folder-note's relationship arrays are **owned by check 8**.
   - A missing service in a ticket's `services:` array is **owned by check 6**.
   - Dead catalogue entries in `index.md` are **owned by check 5** - skip wikilinks in `index.md` here.
   - A ticket-id link (`[[{{TICKET_PREFIX}}-NNNN]]`, `[[VLT-NNNN]]`) resolves when `tickets/<id>/` or `tickets/_archive/<id>/` exists, even without an `<id>.md` inside. A `[[{{TICKET_PREFIX}}-NNNN]]` with no folder is an external {{TRACKER_NAME}} reference: skip it. Only a `[[VLT-NNNN]]` with no folder in either place is broken. The same rule applies to index entries in check 5.
2. **Orphan pages** - pages under `wiki/` (excluding `index.md`, `log.md`, `brag.md`, `journal/*`) with zero inbound wikilinks. Orphan means **unreachable by navigation**: inbound links from `log.md`, `journal/*` or `brag.md` do **not** count. A concept page linked only from `log.md` is an orphan. A concept page linked from another concept page or a folder-note is not. List each with its `type:`.
3. **Ticket folders missing `state.md`** - any folder directly under `tickets/`, excluding `_archive/`, without a `state.md`. Today's shape is `{{TICKET_PREFIX}}-NNNN.md`, `state.md`, `plan.md`, `review.md`, `evidence/`. An older folder with `context.md`, `notes.md`, `proof.md` or `council.md` is valid. Only a missing `state.md` is a finding.
4. Removed in 1.10.0 (stale status needs file mtimes or git).
5. **Index drift** - pages under `wiki/` that are not listed in `wiki/index.md`, and `index.md` entries that point to pages that no longer exist.
6. **Missing service folders** - services named in a ticket `state.md` `services:` array with no `wiki/services/<Service>/<Service>.md` folder-note.
7. Removed in 1.10.0 (contradiction review needs file mtimes).
8. **Service-graph drift** - for each service folder-note, read the four relationship arrays (`calls`, `depends_on`, `emits_events_to`, `subscribes_to`) and compare with `wiki/concepts/service-graph.md`:
   - Edges declared in frontmatter but missing from the graph page's diagram or table.
   - Edges on the graph page that no service declares any more.
   - Asymmetric event edges: `A.emits_events_to: [[B]]` without `B.subscribes_to: [[A]]`, or the reverse.
   - Relationship links to a service with no folder-note.
9. Removed in 1.10.0 (concept suggestions are advice, not breaks).
10. Removed in 1.10.0 (kit drift needs reads outside the vault and git).
11. Removed in 1.10.0 (claim drift needs service repo reads and git; no unmarked-claims backlog).
12. Removed in 1.10.0 (strays need a layout script; a person runs it).

## Report format

```
## Lint report - <date>

### Broken wikilinks (N)
- wiki/concepts/foo.md -> [[missing-page]]

### Orphan pages (N)
- wiki/concepts/bar.md (concept)

### Missing state.md (N)
- tickets/{{TICKET_PREFIX}}-NNNN

### Index drift (N)
- not in index: wiki/concepts/baz.md
- dead entry: [[deleted-page]]

### Missing service pages (N)
- Project.Z (named in tickets/{{TICKET_PREFIX}}-NNNN/state.md)

### Service-graph drift (N)
- Project.A declares calls: [[Project.C]] but service-graph.md shows no such edge
- Project.A.emits_events_to: [[Project.D]] without Project.D.subscribes_to: [[Project.A]]
```

After reporting, append to `wiki/log.md`:
`## [YYYY-MM-DD HH:MM] lint | <total-issues> findings`

Then ask the user which findings to address now (if any). Fix only what is explicitly requested.
