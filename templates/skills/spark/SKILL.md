---
name: spark
version: 1.0.0
description: Mine the vault for AI builder-session prototype candidates — scan concepts, tickets, incidents, journal, and service pain points, then propose 3–5 ranked ideas sized to the session length. Use when the user says "spark", "/spark", "what should I prototype", "ideas for the builder session", or it's the morning of the team's AI builder session.
---

Mine `{{VAULT_DIR}}/` for prototype-worthy friction and propose ranked candidates for the AI builder session. The session brief and ground rules live at the top of `wiki/concepts/prototype-ideas.md` — read it first.

## Gather (in order)

1. **The backlog** — `wiki/concepts/prototype-ideas.md`. Existing `seed` entries are first-class candidates; never re-propose something already `built`, `shipped`, or `dead`.
2. **Concepts** — every page in `wiki/concepts/`. Look for documented constraints, failure modes, and workarounds (these are pain wearing a documentation costume).
3. **Tickets** — `tickets/*/state.md` + `notes.md`. `investigated` tickets that stalled are prime material: the investigation is done, the runway wasn't there.
4. **Incidents & runbooks** — anything manual, repetitive, or fragile enough to need a runbook is automatable.
5. **Recent journal** — `wiki/journal/` current month. Fresh friction the user has felt but not filed.
6. **Service folder-notes** — skim `## Architecture` / gotcha callouts for "lives with it" pain.

## Filter & rank

A good candidate must be:

- **New build, not BAU** — it must not advance a sprint task. If it overlaps an `active` ticket, reshape it so it explores rather than delivers (e.g. spike an alternative, not finish the feature).
- **Demoable within the session with AI in the cockpit** — a vertical slice someone can show at the end. Cut scope until that's true.
- **Traceable to real pain** — every proposal cites the vault page/ticket that surfaced it.
- **Ambitious** — apply the intimidation check: if it would feel comfortable in a normal sprint, raise the ambition or drop it. Prefer `stretch` and `intimidating` over `comfortable`.

Rank by: pain frequency (how many pages/tickets touch it) × learning value × demo impact.

## Output

Present 3–5 candidates:

```
## Spark — <date>

### 1. <title> — <ambition>
**Pitch:** <one sentence>
**Pain:** [[source-page]] / [[{{TICKET_PREFIX}}-NNNN]] — <why it hurts>
**Session slice:** <exactly what would be demoable at show-and-tell>
**Intimidation check:** <what makes this a stretch>
```

Then:

1. Append any **newly discovered** seeds (ones not already on the backlog) to `wiki/concepts/prototype-ideas.md` — even unpicked ones; the backlog compounds.
2. Append to `wiki/log.md`: `## [YYYY-MM-DD HH:MM] spark | proposed N candidates for builder session`.
3. Ask which one the user is building. On their pick, offer to kick off `/prototype` (companion skill, if installed) with the session slice as the brief — otherwise scaffold the build directly.

## After the session (reminder, not enforcement)

The closing loop is `/journal`: the build gets a journal entry and a `wiki/brag.md` line, and the idea's status on the backlog flips to `built` with a link to what was shown.
