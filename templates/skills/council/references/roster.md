# Council roster

The fixed set of seats `/council` selects from. Each seat is an agent file `~/.claude/agents/council-<seat>.md`; this file says when to convene it. Edit here to change the council. The council never invents a seat that is not listed: a missing perspective is a proposed edit to this file.

Tiers: `core` seats run on every fork that touches code. `optional` seats run when their "convene when" line fits the fork, when the user names them, or when they are pulled back from the `Left out:` list.

## simplicity (core)
- Lens: smallest change, least new surface, what can be deleted.
- Flags: speculative abstractions, new tables or flags nothing needs, the precedented path being ignored.
- Convene when: always, on a code fork.

## robustness (core)
- Lens: failure modes, data loss, reversibility, what pages someone at 3am.
- Flags: corrupting paths, half-success states, assumed deployed state, rollbacks that are not one step.
- Convene when: always, on a code fork.

## domain (core)
- Lens: ubiquitous language, contract shape, layering, where the invariant lives.
- Flags: modeller jargon, invariants in handlers, ADR contradictions, source shapes leaking across a boundary.
- Convene when: always, on a code fork.

## contrarian (optional)
- Lens: the strongest case against option A as stated, and against the question itself.
- Flags: groupthink, the option nobody listed, the reason this is the wrong fork.
- Convene when: the fork is not about code (process, staffing, tooling, sequencing); the user asks; or round 1 is unanimous and contrarian was not in the slate. In that last case it gets the brief plus the three verdicts, one round.

## delivery (optional)
- Lens: what ships, in what order, with who is available, and what it keeps costing.
- Flags: underestimated effort, scope creep, a small first step hiding an ongoing cost, the simpler option overlooked for schedule reasons.
- Convene when: options differ in who does the work or when it lands; a fork spans more than one ticket or team; build-vs-buy.

## risk (optional)
- Lens: exposure and blast radius.
- Flags: attack surface, data custody (whichever regulations govern your data), single points of failure, compliance, secrets in the wrong place.
- Convene when: the fork touches auth, personal or financial data, an external integration, or anything a regulator or auditor reads.

## experience (optional)
- Lens: the domain expert or customer on the receiving end.
- Flags: copy, friction, internal-looking changes that hurt the user, unstated assumptions about how people work.
- Convene when: the fork changes a screen, a notification, an email, or any user-facing wording.

## Adding a seat
Copy a block: `## <name> (<tier>)`, Lens, Flags, Convene when. Write the matching `~/.claude/agents/council-<name>.md` from an existing seat, keeping the preamble, tools, model and output shape. If the new seat overlaps an existing one, sharpen the difference or merge.
