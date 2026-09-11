---
name: council
version: 1.2.0
description: Convene three fresh-context seats (simplicity, robustness, domain) to judge a design fork before acting on it, then record the decision with its dissent. Use without being asked whenever a plan step or an imminent edit has two or more viable options, or touches a migration, a contract or DTO shape, a data model, a cross-service edge, or anything hard to reverse after deploy. Also use when the user says "council", "/council", "get a second opinion", or "what would the seats say".
argument-hint: "<the fork, or the ticket id whose plan has one>"
---

Judge a design fork with three seats that cannot see each other's reasoning, then decide with the dissent kept. Two rounds, never more. Consensus is not the goal; a recorded decision is.

## Step 1 - Name the fork

Write the brief before spawning anything. One paragraph plus a list:
- The decision in one sentence.
- Options A, B, (C). Each in one or two lines. "Do nothing" counts if viable. For an idea typed in chat, the idea is A and the status quo or the nearest existing pattern is B.
- The files and services the fork touches, as paths.
- The ticket id.

If you cannot write two viable options, there is no fork. Say so and stop.

## Step 2 - Round 1, parallel, blind

Spawn `council-simplicity`, `council-robustness`, and `council-domain` in one message so they run together. Each gets the identical brief and nothing else: no prior reasoning, no hint of your preference, no other seat's answer. Each returns the fixed shape from its agent file.

## Step 3 - Round 2, once

If all three prefer the same option, skip this round.

Otherwise send each seat the other two seats' answers verbatim and one instruction: hold or move, with the reason in one sentence, same output shape. One round. Do not ask again.

## Step 4 - Answer, then ledger

The chat response is the deliverable: chosen option, the split, the one fact that would flip the dissenting seat. Short. The user decides. Do not act on the fork until they do.

If the fork belongs to a ticket, append one section to `tickets/<id>/council.md` (create it with `type: ticket` frontmatter on first use; write atomically, temp file then rename). One file per ticket, one short section per fork, never rewritten:

```
## YYYY-MM-DD - <decision in one sentence>
Options: A <one line>; B <one line>
- simplicity: <preferred> - <worst risk of the chosen option, one line>
- robustness: <preferred> - <one line>
- domain: <preferred> - <one line>
Ruling: <option>, by <user | pending>. Dissent: <seat(s)>.
```

Seat lines are quoted, not paraphrased: the orchestrator has been in the conversation and is biased, and quoting makes that bias a visible edit. A fork that is a small part of the ticket gets a small entry. No ticket, no file.

Draft an ADR in `wiki/decisions/NNNN-slug.md` only when the ruling passes all three tests in [[decisions]]: hard to reverse, surprising without context, a genuine trade-off. Most forks do not. Link it from the ledger entry when written.

Append a `log.md` entry only when a file was written: `## [YYYY-MM-DD HH:MM] page | council: <decision> for <id>`. Run `date` first.

## Rules

- Seats get the brief and the repo. Nothing else, ever, in round 1.
- Two rounds is the ceiling. A seat that keeps moving is noise, not signal.
- Never merge options into a compromise the seats did not propose.
- The council gate hook denies edits to migration and contract paths until the ticket ledger `council.md` exists for an active ticket. If the fork is not there, tell the user and let them bypass with the marker file the hook names.
