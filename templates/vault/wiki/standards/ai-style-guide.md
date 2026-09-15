---
type: standard
date: {{TODAY}}
---

# AI Style Guide

House rules for AI-assisted work. The root [[CLAUDE]] references this file and treats it as load-bearing.

## Progress reports and decision asks

Any message that reports progress or asks for a decision uses this card, in this order, nothing else at the top level:

````
## {{TICKET_PREFIX}}-NNNN - <three or four words>
**Problem.** One sentence, in product terms.
**Fix.** One sentence.
**Status.** Where it is, and whether code exists yet.
**Blocked on you.** Numbered, each one an action the reader can take. "Nothing" if nothing.
**Changed since last time.** One or two lines. Omit on a first report.
````

Rules that make it work:

- Detail goes in `tickets/{{TICKET_PREFIX}}-NNNN/plan.md` and is *pointed at*, never inlined. "Reasoning in plan.md" beats three paragraphs.
- Findings, rebuttals, subagent verdicts and evidence tables are ticket-file content, not message content.
- One card per ticket. Two tickets means two cards, never merged into a narrative.
- Recommend, do not enumerate. "Keep it (my call)" beats a balanced survey of both options.
- Write the card first, then ask whether any sentence below it must be read *now* to decide. If not, it belongs in the ticket file.

Why: the reader runs several agent panes at once and context-switches between them, so a report has to be readable cold after an hour somewhere else. Long synthesis prose fails that even when every line is correct, and anything that makes the reader hunt for the ask has already cost the context switch.

This rule belongs here and in the root schema, not in per-project agent memory. Agent memory is scoped per project directory, so a worktree or sibling-repo pane cannot load it, and the rule silently does not exist for exactly the sessions that need it most.

## Prose and tone

Write so it reads like a person wrote it quickly and clearly, not like polished AI copy.

- No em dashes or en dashes as connectors. Use a comma, period, parentheses, or colon. Split long sentences.
- No literary flourishes: drop the rule-of-three lists, the "not just X but Y" constructions, the throat-clearing intros.
- Plain and direct over formal. Contractions are fine. Get to the point.
- Concrete over abstract: prefer the specific noun or number to the adjective. Cut filler adjectives.
- Test: if a sentence sounds like marketing copy, rewrite it.
