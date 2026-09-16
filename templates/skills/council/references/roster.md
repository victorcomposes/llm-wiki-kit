# Council roster

The fixed set of seats `/council` selects from. Each seat is an agent file `~/.claude/agents/council-<seat>.md`; this file says when to convene it. Edit here to change the council. The council never invents a seat that is not listed: a missing perspective is a proposed edit to this file.

Tiers: `core` seats run on every fork, whatever the topic. `optional` seats run when one of their `Signals:` matches the brief, when the user names them, or when they are pulled back from the `Left out:` list.

## Selecting the slate

Runs on every fork, before anything is spawned. For each optional seat, check every signal against two things only: the touched paths in the brief, and the decision sentence plus option lines. One line per seat in the brief:
- matched: `Seats: <seat> - <the signal that matched, quoted>`
- not matched: `Left out: <seat> - no signal; nearest miss <signal>`

A seat matched by one signal is in. Never drop a matched seat to keep the slate small. Never add an unmatched seat on a hunch; if a hunch keeps recurring, add it here as a signal.

## simplicity (core)
- Lens: smallest change, least new surface, what can be deleted.
- Flags: speculative abstractions, new tables or flags nothing needs, the precedented path being ignored.
- Convene when: always.

## robustness (core)
- Lens: failure modes, data loss, reversibility, what pages someone at 3am.
- Flags: corrupting paths, half-success states, assumed deployed state, rollbacks that are not one step.
- Convene when: always.

## domain (core)
- Lens: ubiquitous language, contract shape, layering, where the invariant lives.
- Flags: modeller jargon, invariants in handlers, ADR contradictions, source shapes leaking across a boundary.
- Convene when: always.

## contrarian (core)
- Lens: the strongest case against option A as stated, and against the question itself.
- Flags: groupthink, the option nobody listed, the reason this is the wrong fork.
- Convene when: always.

## delivery (optional)
- Lens: what ships, in what order, with who is available, and what it keeps costing.
- Flags: underestimated effort, scope creep, a small first step hiding an ongoing cost, the simpler option overlooked for schedule reasons.
- Signals: touched paths span two or more repos; the decision or an option names another team, a release, a deadline, a framework or package version, build vs buy, or who does the work; the ticket's `state.md` lists `tickets-related`.

## risk (optional)
- Lens: exposure and blast radius.
- Flags: attack surface, data custody (whichever regulations govern your data), single points of failure, compliance, secrets in the wrong place.
- Signals: touched paths contain `Auth`, `Identity`, `Security`, `Secrets`, `appsettings`, `KeyVault`, `Http`, `Client`, `Integration`, `Webhook`, or a `Controllers` folder; the decision or an option names a token, a credential, a third party, personal or financial data, an audit, or a regulator.

## experience (optional)
- Lens: whoever is on the receiving end - usually the domain expert or customer, and on internal tooling the operator who has to live with it.
- Flags: copy, friction, internal-looking changes that hurt the user, unstated assumptions about how people work; on tooling, a wrong answer with no error, and having to know which pane or mode can do what.
- Signals: touched paths contain a frontend folder, `.html`, `.ts` under a frontend folder, `Templates`, `Email`, `Notification`, `Views`, `Resources`, or `.resx`; the decision or an option names a screen, a label, a status the user sees, a message, an email, copy, or wording. **Operator ergonomics:** touched paths contain `scripts/`, `.claude/hooks/`, a user-scope agent config folder, a `SKILL.md`, or a `CLAUDE.md`; or the decision or an option names a pane, tab, workspace, session, prompt, slash command, or what the agent does by default.

## Adding a seat
Copy a block: `## <name> (<tier>)`, Lens, Flags, and either `Convene when: always` for core or `Signals:` for optional. Write the matching `~/.claude/agents/council-<name>.md` from an existing seat, keeping the preamble, tools, model and output shape. If the new seat overlaps an existing one, sharpen the difference or merge.
