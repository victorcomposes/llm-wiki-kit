# Obsidian LLM Wiki — Pattern, Sources & Implementation Blueprint

A self-contained guide to building Karpathy's "LLM Wiki" pattern in Obsidian with Claude Code. Consolidates the canonical idea file (`llm-wiki.md`, included below) with primary sources and a concrete folder/setup proposal.

---

## Part 1 — The pattern (from Karpathy)

> Lightly condensed from [karpathy/llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — full text saved locally at `{{VAULT_DIR}}/meta/llm-wiki.md`.

### Core idea

Typical LLM-over-documents setups (NotebookLM, RAG, file uploads) rediscover knowledge from scratch on every query. The LLM Wiki pattern is different: the LLM **incrementally builds and maintains a persistent wiki** — a structured, interlinked collection of markdown files that sits between you and the raw sources.

When you add a source, the LLM doesn't just index it. It reads it, integrates it into existing entity/concept pages, flags contradictions, and updates the synthesis. Knowledge is compiled once and kept current, not re-derived each time. The wiki is a **persistent, compounding artifact**.

You rarely write the wiki yourself. You curate sources and ask questions; the LLM does the summarizing, cross-referencing, filing, and bookkeeping. Karpathy's framing: *Obsidian is the IDE, the LLM is the programmer, the wiki is the codebase.*

### Architecture — three layers

1. **Raw sources** — articles, papers, images, data files. Immutable; the LLM reads but never modifies.
2. **The wiki** — LLM-owned markdown files: summaries, entity pages, concept pages, comparisons, syntheses.
3. **The schema** — `CLAUDE.md` (Claude Code) or `AGENTS.md` (Codex). Tells the LLM the conventions and workflows. This is what turns a generic chatbot into a disciplined wiki maintainer. You and the LLM co-evolve it.

### Operations — three commands

- **Ingest.** Drop a source into raw; LLM reads it, discusses takeaways, writes a summary page, updates index, updates relevant entity/concept pages, appends to log. A single source typically touches 10–15 pages.
- **Query.** LLM searches the wiki, reads relevant pages, synthesizes an answer with citations. *Good answers should be filed back as new pages* so explorations compound.
- **Lint.** Periodic health check: contradictions, stale claims, orphan pages, important-but-undocumented concepts, missing cross-references, suggested research directions.

### The two anchor files

- **`index.md`** — content catalog. Every page listed with a link and one-line summary, grouped by category. The LLM updates it on every ingest and reads it first on every query. Works well up to ~hundreds of pages without needing embedding-based RAG.
- **`log.md`** — append-only chronological ledger. Convention: `## [YYYY-MM-DD] action | title`. Parseable with `grep "^## \[" log.md | tail -5`.

### Why it works

> The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping. Humans abandon wikis because the maintenance burden grows faster than the value. LLMs don't get bored, don't forget to update a cross-reference, and can touch 15 files in one pass. — *Karpathy*

---

## Part 2 — Primary sources

### Canonical pattern
- [Karpathy's tweet (Apr 2, 2026)](https://x.com/karpathy/status/2039805659525644595)
- [karpathy/llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — local copy: `{{VAULT_DIR}}/meta/llm-wiki.md`

### The glue: Obsidian Skills
- [kepano/obsidian-skills on GitHub](https://github.com/kepano/obsidian-skills) (~33k stars, MIT). Five official skills published by Obsidian's CEO Steph Ango:
  - `obsidian-markdown` — wikilinks, embeds, callouts, properties
  - `obsidian-bases` — database views, filters, formulas
  - `json-canvas` — visual node/edge canvases
  - `obsidian-cli` — drive the vault programmatically
  - `defuddle` — extract clean markdown from web pages
- Install: `npx skills add https://github.com/kepano/obsidian-skills`

### Obsidian CLI
- [Official Obsidian CLI docs](https://help.obsidian.md/cli) — shipped Feb 2026 in v1.12, ~115 commands. Enable in Settings → General → Command line interface. Obsidian must be running for commands to work.

### Claude Code mechanics
- [Slash commands docs](https://code.claude.com/docs/en/slash-commands.md) — markdown files in `.claude/commands/` (project) or `~/.claude/commands/` (personal), with optional YAML frontmatter for argument hints and tool permissions.
- `CLAUDE.md` loads automatically at session start — this is where the schema layer lives.

### Capture
- [Obsidian Web Clipper](https://obsidian.md/clipper) — official browser extension. Clips articles (and YouTube transcripts) straight into your vault folder of choice.

### Optional — wiki search
- [qmd](https://github.com/tobi/qmd) — local hybrid (BM25 + vector) search over markdown with LLM re-ranking. CLI + MCP server. Only needed once the wiki outgrows `index.md` as a navigation device.

---

## Part 3 — Proposed structure

Follow Karpathy's gist directly. The doc is deliberately abstract — every choice below is one concrete instantiation.

```
my-vault/
├── CLAUDE.md                # Layer 3: schema. Conventions, link style,
│                            # when to spawn vs extend a page, ingest/lint
│                            # workflows. Co-evolved with the LLM.
├── .claude/
│   ├── commands/
│   │   ├── ingest.md        # /ingest <path-or-url>
│   │   ├── query.md         # /query <question>  (optional — Claude can
│   │   │                    #   answer without it; the command enforces
│   │   │                    #   "read index.md first, then cite")
│   │   └── lint.md          # /lint — broken links, orphans, contradictions
│   └── skills/              # Drop in from kepano/obsidian-skills
│       ├── obsidian-markdown/
│       ├── obsidian-bases/
│       ├── json-canvas/
│       ├── obsidian-cli/
│       └── defuddle/
│
├── raw/                     # Layer 1: immutable. Never edit by hand.
│   ├── articles/            # By-type, not by-topic — type is stable,
│   ├── papers/              # topic taxonomies drift. Topic discovery is
│   ├── books/               # what the wiki is for.
│   ├── podcasts/
│   ├── assets/              # Auto-downloaded images (see Tips below)
│   └── inbox/               # Fleeting notes; ingest promotes them out
│
└── wiki/                    # Layer 2: LLM-owned. Flat by default —
    │                        # Obsidian wikilinks resolve globally, so
    │                        # nesting only buys visual organization.
    ├── index.md             # Karpathy's content catalog
    ├── log.md               # Append-only: ## [YYYY-MM-DD] action | title
    ├── _people/             # Optional subfolders only if a category
    ├── _concepts/           #   grows past ~50 pages. Start flat.
    └── _sources/            # One page per raw/ document
```

### Three decisions worth making upfront

1. **`raw/` by type or by topic.** Pick type. Topic taxonomies drift as interests shift; file type doesn't. Topic discovery is what the wiki is for.
2. **Flat `wiki/` vs nested.** Karpathy's gist is flat. Wikilinks resolve regardless of folder. Start flat; add `_people/` / `_concepts/` only when a category gets unwieldy.
3. **What goes in CLAUDE.md.** At minimum:
   - Link convention: always `[[Wikilink]]`, never markdown links
   - When to spawn a new concept page vs extend an existing one
   - Frontmatter schema (tags, source, date, source-count)
   - The ingest workflow as a numbered procedure
   - "After every ingest, append one line to `log.md`"
   - When to file a query response back as a wiki page

   Start by paraphrasing Karpathy's Operations section into this file, then refine.

---

## Part 4 — Setup, in order

1. Enable the Obsidian CLI (Settings → General → Command line interface).
2. `cd` into your vault. Run `npx skills add https://github.com/kepano/obsidian-skills`.
3. Drop `{{VAULT_DIR}}/meta/llm-wiki.md` content into `CLAUDE.md` as the starting schema; edit conventions to match your preferences.
4. Write the three slash commands (each is a markdown file with a prompt — see [Slash commands docs](https://code.claude.com/docs/en/slash-commands.md)).
5. Install Obsidian Web Clipper; configure it to save into `raw/articles/`.
6. Ingest one article end-to-end. Read what Claude produced. Tune `CLAUDE.md` based on what was wrong or missing.
7. Repeat. The schema converges within ~10 ingests.

---

## Part 5 — Tips and tricks (from Karpathy's gist)

- **Download images locally.** Settings → Files and links → set "Attachment folder path" to `raw/assets/`. Settings → Hotkeys → bind "Download attachments for current file" to e.g. Ctrl+Shift+D. After clipping an article, hit the hotkey. LLMs can't read inline markdown images in one pass — workaround is to read the text first, then view referenced images separately.
- **Obsidian's graph view** is the best way to see the wiki's shape — hubs, orphans, clusters.
- **Marp** (markdown slide format, Obsidian plugin) — useful for generating presentations directly from wiki content.
- **Dataview** plugin runs queries over page frontmatter. If your schema mandates YAML frontmatter (tags, dates, source counts), Dataview gives you dynamic tables and lists for free.
- **The wiki is just a git repo.** Version history, branching, collaboration for free. Commit after each ingest if you want a perfect audit trail.

---

## Closing note

Karpathy's gist closes by saying: this document describes the *idea*, not an implementation — everything is optional and modular. The blueprint above is one concrete instantiation. The right move is to use it as a starting point, then let the schema co-evolve with your actual use over the first few weeks.
