---
name: council
version: 2.1.0
description: Convene fresh-context seats from a fixed roster (simplicity, robustness, domain, contrarian on every fork; delivery, risk, experience when a roster signal matches) to judge a design fork before acting on it, then record the decision with its dissent and the full seat reports. Use without being asked whenever a plan step or an imminent edit has two or more viable options, or touches a migration, a contract or DTO shape, a data model, a cross-service edge, or anything hard to reverse after deploy. Also use when the user says "council", "/council", "get a second opinion", or "what would the seats say".
argument-hint: "<the fork, or the ticket id whose plan has one>"
---

Judge a design fork with seats that cannot see each other's reasoning, then decide with the dissent kept. Two rounds, never more. Consensus is not the goal; a recorded decision is.

## Step 1 - Name the fork and the slate

Read `references/roster.md`. Write the brief before spawning anything. One paragraph plus a list:
- The decision in one sentence.
- Options A, B, (C). Each in one or two lines. "Do nothing" counts if viable. For an idea typed in chat, the idea is A and the status quo or the nearest existing pattern is B.
- The files and services the fork touches, as paths.
- The ticket id.

Then select the slate, on every fork, whatever the topic. The four core seats are always in. For each optional seat, check every `Signals:` line in the roster against the touched paths and the decision and option lines, nothing else. Write one line per seat:
- `Seats:` core seats by name, then each matched optional seat with the signal that matched, quoted.
- `Left out:` each unmatched optional seat with its nearest-miss signal, so the user can pull it back by name.

One matched signal is enough to convene. Never drop a matched seat to keep the slate small; never add an unmatched seat on a hunch. Only roster seats. A perspective the roster lacks is a proposed edit to `references/roster.md`, never a one-off seat.

If you cannot write two viable options, there is no fork. Say so and stop.

## Step 1b - Gate, only when the user asked

If the user's own prompt contains "council" or `/council`, present the brief's `Seats:` and `Left out:` lines and stop. "Proceed", "yes", "run it" spawns. Anything else is a change: drop, add or swap a seat, or re-brief one, then show the slate again. Loop until they say go. `no council` anywhere in the prompt skips the gate, as it skips the hook.

If the council is self-invoked, from a plan step, a hook nudge, or a denied edit, there is no gate. Spawn at once and state the slate in the answer. Hook nudges never contain the word "council", so the two cases do not overlap.

## Step 2 - Round 1, parallel, blind

Spawn every seat in the slate in one message so they run together. Each gets the identical brief and nothing else: no prior reasoning, no hint of your preference, no other seat's answer. Each returns the fixed shape from its agent file, which includes a `Brief wrong:` line. Treat a non-empty `Brief wrong:` as a correction to record, not an objection to argue.

## Step 3 - Round 2, once

If every seat prefers the same option, skip this round. Contrarian sat in round 1, so unanimity has already survived an attack.

Otherwise send each seat the other seats' answers verbatim and one instruction: hold or move, with the reason in one sentence, same output shape. One round. Do not ask again.

## Step 4 - Answer, then ledger

The chat response is the deliverable. Short, in this order:
- Recommendation: the option, one or two sentences.
- Where the seats agreed.
- Tensions and how they resolve: each split, and why one side wins in this context. Never split the difference.
- Open questions: what a seat could not close, and the one fact that would flip the dissenting seat.
- Seats: one quoted line each.

The user decides. Do not act on the fork until they do.

If the fork belongs to a ticket, write the seat reports and append one section to `tickets/<id>/council.md`. Create the ledger with `type: ticket` frontmatter on first use; write atomically, temp file then rename. One ledger per ticket, one short section per fork, never rewritten.

Seat reports go to `tickets/<id>/council/<YYYY-MM-DD>-<slug>/<seat>.md`, one file per seat, `type: ticket` frontmatter, round 1 and round 2 under `## Round 1` and `## Round 2`, the seat's words verbatim. In a vault worktree pane the new folder gets its one `git add` before the explicit-path commit. The gate hook reads only `council.md`, which is why the reports live apart: a seat quoting `Clears:` grammar can never reach the parser.

```
## YYYY-MM-DD - <decision in one sentence>
Options: A <one line>; B <one line>
Seats: <names>. Left out: <names, or none>.
- simplicity: <preferred> (<hold | moved from X>) - "<one quoted line>"
- robustness: <preferred> - "<one quoted line>"
- domain: <preferred> - "<one quoted line>"
- contrarian: <preferred> - "<one quoted line>"
- <optional seat>: <preferred> - "<one quoted line>"
Ruling: pending (<option> recommended). Dissent: <seat(s), or none>.
Brief corrected: <a seat's Brief wrong line, when any>
Facts closed: <what the orchestrator verified between rounds, when any>
Open: <what nobody could close, when any>
Clears: <glob>, <glob>
Reports: [simplicity](council/<date>-<slug>/simplicity.md), [robustness](...), [domain](...), [contrarian](...)
```

When the user rules, edit the Ruling line to `Ruling: <option>, by <user>.` and nothing else. `Brief corrected`, `Facts closed` and `Open` appear only when non-empty. `Reports:` links are path-qualified markdown, never wikilinks, because seat filenames repeat across forks.

`Clears:` only when the fork is about a gated edit (migration, contract, DTO, event). Globs are relative to the root dev folder, forward slashes, `*` and `**`; name the file when it exists, else the narrowest folder, for example `MyService/**/Migrations/**`. The council gate honours a Clears line only once the Ruling line no longer contains the word `pending`.

Seat lines are quoted, not paraphrased: the orchestrator has been in the conversation and is biased, and quoting makes that bias a visible edit. A fork that is a small part of the ticket gets a small entry. No ticket, no files.

Draft an ADR in `wiki/decisions/NNNN-slug.md` only when the ruling passes all three tests in [[decisions]]: hard to reverse, surprising without context, a genuine trade-off. Most forks do not. Link it from the ledger entry when written.

Append a `log.md` entry only when a file was written: `## [YYYY-MM-DD HH:MM] page | council: <decision> for <id>`. Run `date` first.

## Rules

- Seats get the brief and the repo. Nothing else, ever, in round 1.
- Only roster seats, selected by roster signals on every fork. Propose a roster edit instead of inventing a seat or a signal.
- The gate is non-negotiable when the user typed "council", unless they wrote `no council`. It never applies to a self-invoked run.
- Two rounds is the ceiling. A seat that keeps moving is noise, not signal.
- Never merge options into a compromise the seats did not propose.
- The council gate hook denies edits to migration and contract paths unless a ruled ledger entry in an active ticket has a `Clears:` glob matching the file. If the fork is not there, tell the user and let them bypass with the marker file the hook names.
