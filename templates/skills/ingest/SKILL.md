---
name: ingest
version: 1.1.0
description: Read a source (URL or file path) and integrate it into the wiki — Karpathy's LLM Wiki pattern. Use when the user says "ingest", "/ingest", "add this to the wiki", "file this source", or hands over a URL/path to be folded into the vault.
---

Ingest the source the user provided.

This is the Karpathy LLM Wiki "ingest" operation. The full pattern is in `{{VAULT_DIR}}/meta/llm-wiki.md` — read it if you haven't this session.

## Steps

1. **Read the source**:
   - If the argument looks like a URL, use the `defuddle` skill (from `kepano/obsidian-skills`, if installed) to fetch clean markdown; otherwise fetch the page and strip it to readable text.
   - If it's a file path, read it directly.
   - If it's neither, ask the user.
2. **Classify** the source. Decide which category it belongs to:
   - `concept` — a domain idea (flow, mechanism, design pattern) → `{{VAULT_DIR}}/wiki/concepts/<slug>.md`
   - `incident` — a postmortem or outage analysis → `{{VAULT_DIR}}/wiki/incidents/<slug>.md`
   - `runbook` — a "how we do X" procedure → `{{VAULT_DIR}}/wiki/runbooks/<slug>.md`
   - `service-note` — substantial info about a single service → update `{{VAULT_DIR}}/wiki/services/<Service>/<Service>.md` (the folder-note). If the info is large or specialised (e.g. an architecture deep-dive, a dependency map), add it as a sibling page inside the same folder and link to it from the folder-note rather than dumping everything into one file.
   - `standard` — a rule/convention → `{{VAULT_DIR}}/wiki/standards/<slug>.md`
   - `meta` — about the wiki itself, the tooling, the pattern → `{{VAULT_DIR}}/meta/<slug>.md`
   - Tell the user your classification and ask if they want to override.
3. **Discuss takeaways** with the user. Pull out 3-7 key points. Confirm understanding before writing.
4. **Write the page** with proper frontmatter (per the root schema) and Obsidian wikilinks to related existing pages. If a referenced concept doesn't have its own page yet, use `[[Concept Name]]` anyway and note the missing page for `/lint` to flag later.
5. **Update existing pages** that this source touches. A single source can update 5-15 pages. Examples:
   - If it's a concept that involves a service → update the service folder-note
   - If it reveals a service relationship (A calls B, A depends on B, A emits to B, A subscribes to B) → update the **typed relationship frontmatter** on the affected service folder-note(s) — `calls`, `depends_on`, `emits_events_to`, `subscribes_to` — and add a one-line entry under the folder-note's `## Relationships` section explaining the *why* and the failure mode
   - If any relationship frontmatter changed in this ingest → rebuild `{{VAULT_DIR}}/wiki/concepts/service-graph.md` from all service folder-notes (full scan; inverse lookups depend on it) and append a `graph | rebuilt service-graph` entry to `log.md`
   - If it contradicts an existing page → add a `> [!warning] Updated <date>` callout to the older page
   - If it introduces a new entity (person, system) → create a stub page if warranted
6. **Update `wiki/index.md`**: add the new page under the right category with a one-line summary.
7. **Append to `wiki/log.md`**:
   `## [YYYY-MM-DD HH:MM] ingest | <source> → <page-path>`
8. Report back: which pages were created, which were updated, which wikilinks point to pages that don't yet exist (so the user knows what `/lint` will find).

Honour the root schema conventions throughout.
