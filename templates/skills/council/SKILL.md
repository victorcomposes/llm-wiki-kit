---
name: council
version: 1.0.0
description: Convene three fresh-context seats (simplicity, robustness, domain) to judge a design fork before acting on it, then record the decision with its dissent. Use without being asked whenever a plan step or an imminent edit has two or more viable options, or touches a migration, a contract or DTO shape, a data model, a cross-service edge, or anything hard to reverse after deploy. Also use when the user says "council", "/council", "get a second opinion", or "what would the seats say".
argument-hint: "<the fork, or the ticket id whose plan has one>"
---

Judge a design fork with three seats that cannot see each other's reasoning, then decide with the dissent kept. Two rounds, never more. Consensus is not the goal; a recorded decision is.

## Step 1 - Name the fork

Write the brief before spawning anything. One paragraph plus a list:
- The decision in one sentence.
- Options A, B, (C). Each in one or two lines. "Do nothing" counts if viable.
- The files and services the fork touches, as paths.
- The ticket id.

If you cannot write two viable options, there is no fork. Say so and stop.

## Step 2 - Round 1, parallel, blind

Spawn `council-simplicity`, `council-robustness`, and `council-domain` in one message so they run together. Each gets the identical brief and nothing else: no prior reasoning, no hint of your preference, no other seat's answer. Each returns the fixed shape from its agent file.

## Step 3 - Round 2, once

If all three prefer the same option, skip this round.

Otherwise send each seat the other two seats' answers verbatim and one instruction: hold or move, with the reason in one sentence, same output shape. One round. Do not ask again.

## Step 4 - Record

Write `tickets/<id>/council.md` atomically (temp file, then rename):

```
---
type: ticket
date: YYYY-MM-DD
---
# Council - <decision in one sentence>

## Brief
<the Step 1 brief>

## Seats
<each seat's final answer, verbatim, not paraphrased>

## Decision
Chosen: <option>
Dissent: <seat(s) that preferred otherwise, and their stated worst risk of the chosen option>
Recommended by orchestrator: <yes | no, and why in one line>
```

Verbatim matters: the orchestrator has been in the conversation and is biased. Quoting the seats makes that bias a visible edit rather than a silent one.

Draft an ADR in `wiki/decisions/NNNN-slug.md` only when the decision passes all three tests in [[decisions]]: hard to reverse, surprising without context, a genuine trade-off. Most forks do not. Link the ADR from `council.md` when one is written.

Append a `log.md` entry: `## [YYYY-MM-DD HH:MM] page | council: <decision> for <id>`. Run `date` first.

## Step 5 - Hand the decision to the user

Report in this order, short: chosen option, the split, the one fact that would flip the dissenting seat. The user decides. Do not act on the fork until they do.

## Rules

- Seats get the brief and the repo. Nothing else, ever, in round 1.
- Two rounds is the ceiling. A seat that keeps moving is noise, not signal.
- Never merge options into a compromise the seats did not propose.
- The council gate hook denies edits to migration and contract paths until `council.md` exists for an active ticket. If the fork is not there, tell the user and let them bypass with the marker file the hook names.
