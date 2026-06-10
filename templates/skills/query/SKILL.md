---
name: query
version: 1.0.0
description: Answer a question against the wiki — read the catalogue, synthesize from relevant pages with citations, and offer to file good answers back as new pages so explorations compound. Use when the user says "query", "/query", "ask the wiki", "what does the wiki say about", or poses a question that the vault should answer.
---

Answer the user's question using the wiki. This is the Karpathy LLM Wiki "query" operation — the discipline that makes explorations compound instead of evaporating into chat history.

## Steps

1. **Read `{{VAULT_DIR}}/wiki/index.md` first.** It's the catalogue. Use it to find the pages relevant to the question — don't grep blindly.
2. **Read the relevant pages** (and follow their `[[wikilinks]]` one hop where it helps). Prefer the wiki's own synthesis over re-deriving from raw sources; consult `{{VAULT_DIR}}/` raw material only when the wiki is thin.
3. **Synthesize an answer** grounded in what you read. **Cite every claim** with the `[[page]]` it came from. If the wiki contradicts itself, surface the contradiction rather than papering over it (and flag it for `/lint`).
4. **Flag gaps.** If the question can't be fully answered from the wiki, say what's missing and suggest what to `/ingest` to fill it.
5. **Offer to file the answer back.** A good comparison, analysis, or discovered connection is worth keeping. Ask the user: *"File this as a wiki page?"* If yes:
   - Pick the right category (usually `concepts/`) and write it with frontmatter and wikilinks.
   - Add it to `wiki/index.md`.
   - Append to `wiki/log.md`: `## [YYYY-MM-DD HH:MM] query | <question> → <page-path>`
   If no, append a lighter log line: `## [YYYY-MM-DD HH:MM] query | <question> (not filed)`.

Keep answers tight and cited. The value of the wiki is that you don't re-derive — you read what's already synthesized and build on it.
