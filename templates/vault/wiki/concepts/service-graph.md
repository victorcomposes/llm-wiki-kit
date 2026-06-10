---
type: concept
date: {{TODAY}}
tags: [architecture, auto-maintained]
auto_maintained: true
---

# Service Graph

The rolled-up view of every service under `{{ROOT_DIR}}` and the relationships declared in their folder-note frontmatter. **Do not hand-edit the sections below** — they're regenerated from the source of truth (each service's frontmatter). Hand-edit the *source* (the service folder-note), then rebuild this page.

## How this page is generated

Read every `{{VAULT_DIR}}/wiki/services/*/*.md` folder-note. From each, pull the four relationship arrays:

- `calls:` — runtime HTTP/gRPC calls (solid arrow `-->`)
- `depends_on:` — build-time / shared-library dependency (dashed arrow `-.->`)
- `emits_events_to:` — async producer → consumer (thick arrow `==>`)
- `subscribes_to:` — async consumer ← producer (inverse of `emits_events_to`; do not draw separately if both sides declared)

Then render two artefacts: a Mermaid diagram and a table. The inverse lookups (`consumed_by`, `subscribed_by`) are computed here — never declared on the source service.

## Diagram

```mermaid
flowchart LR
  %% Empty at bootstrap — populated once any service declares a relationship.
  %% Example of what this will look like once edges exist:
  %%   ProjectA[Project.A] --> ProjectC[Project.C]
  %%   ProjectA -.-> ProjectB[Project.B]
  %%   ProjectD[Project.D] ==> ProjectE[Project.E]
```

## Table

| Service | Calls | Depends on | Emits events to | Subscribes to | Consumed by (derived) |
|---|---|---|---|---|---|
| _(populated on first relationship declaration)_ | | | | | |

## Maintenance protocol

When the agent edits a service folder-note's relationship frontmatter (during `/ingest`, `/ticket`, or any direct edit):

1. Update the source service's frontmatter.
2. Regenerate this page's diagram and table from *all* service folder-notes — not just the one that changed (inverse lookups need a full scan).
3. Append to `wiki/log.md`: `## [YYYY-MM-DD HH:MM] graph | rebuilt service-graph (<N> services, <M> edges)`.
4. If the change introduced a wikilink to a service folder-note that doesn't exist yet, leave the wikilink (it'll be flagged by `/lint`) — do not auto-create the service folder.

## Why this exists

Obsidian's native graph view shows every wikilink as an edge, but it can't distinguish *kinds* of edges (`calls` vs `depends_on` vs `emits_events_to`) and it doesn't give you a readable table. This page is the structured complement: machine-built from frontmatter, source-of-truth for "what talks to what."

For ad-hoc graph queries (e.g. *"every service that calls Project.C"*), use Dataview against the relationship frontmatter directly — this page is the human-readable rollup, Dataview is the query interface.
