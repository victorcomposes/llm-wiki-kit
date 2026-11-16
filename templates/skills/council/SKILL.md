---
name: council
version: 3.0.0
description: "Bring in three fresh delegates in parallel for review or feedback on the user's request, then summarise their findings, disagreements and next steps. Use only when the user's own message says 'council' or '/council'."
---

# Council

Run this only when the user's own message says "council". Never start it yourself.

## Before

Address outstanding PR comments, fix known issues and run the relevant checks. Give the council the updated implementation. Do not defer known fixes until reviews return. If the user wants to discard the implementation and explore new ideas, skip fixes to code that will be replaced.

## Delegates

- Three `general-purpose` delegates, started in parallel in one message with the `Agent` tool.
- Their models come from the line `Council delegates:` in the root schema (`{{ROOT_DIR}}/CLAUDE.md`, or `AGENTS.md`). The kit default is `opus high, opus high, opus medium`. Pass `model:` and `effort:` for each.
- Limit: when the three delegates are the same model, they differ only by fresh context.
- Start each description with the ticket id, for example `{{TICKET_PREFIX}}-NNNN council 1`.
- If a delegate cannot start or fails, report it. Do not substitute another model.

Give each delegate the same request and the same context. For review or feedback, keep their work read-only. Brief:

```
Read only. Do not edit, commit, push, comment on PRs or start subagents.
Request: <the user's request> Repo: <abs path> Base: <sha, for a code review> Context: <what you know>
Return your findings, each with file:line and evidence.
For a code review, end with: Score: <N>/10
```

## While they run

- Start the delegates with `run_in_background: true`. Do not wait idle.
- When a result arrives, check its findings against the code at once. Decide what to fix while the others run.
- Do not edit files while a delegate still reviews the same checkout.
- A turn does not end while a delegate runs.

## Result

Summarise the useful findings, the disagreements and the next steps.

- For a code review, append the summary and the score table to `{{VAULT_DIR}}/tickets/<id>/review.md`:

```
## Council - <YYYY-MM-DD>
Rounds: 2
| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Opus high (1) | 7/10 | 9/10 |
| Opus high (2) | 8/10 | 10/10 |
| Opus medium | 7/10 | 9/10 |
Summary: <findings, disagreements, next steps>
```

- If a delegate gives no score, write `no score`. Do not invent one.
- For any other request, put the summary in the chat reply.

## Rounds

- Each full review pass is one round. A fresh review after fixes starts a new round.
- If you agree with a recommendation, make the change through a subagent, then request a fresh review.
- 3 rounds at most.
- Do not let repeated reviews cause scope creep. Keep the scope limited.
