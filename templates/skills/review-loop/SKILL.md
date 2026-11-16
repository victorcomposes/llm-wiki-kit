---
name: review-loop
version: 1.0.0
description: "Review a ticket's diff in a loop with a fresh Opus reviewer before the draft PR: 3 rounds at most, each finding answered in the review.md ledger. Use before a draft PR opens (root schema section 5, Commit step), or when the user says review loop or /review-loop."
---

# Review loop

A fresh reviewer reviews the diff. You answer each finding with the smallest change. Fight scope creep. Push back when a finding is wrong.

## Budget

- 3 rounds at most. Round 1 is full. Later rounds check only open ids and changed code.
- A round that returns only nits ends the loop. Declined nits and comment, doc or format fixes need no new round. A timeout, an error or no reply is not approval.

## 1. Scope

1. In the ticket checkout, run `git status --short`. Do not stash, discard or include unrelated changes. If unrelated changes are present, limit the review to the change paths.
2. Run `git fetch origin`. Base: `git merge-base HEAD origin/<trunk>`, where the trunk is the repo's default branch. The change is base to working tree in those paths, with untracked files. Use one diff command for all rounds.
3. Write the intent and the out-of-scope in 1-2 sentences. Run the project's verification (build, tests). Do not send code that this change breaks. Name missing or failing checks in the brief.

## 2. Start the reviewer

- Each round, start a fresh read-only reviewer with the `Agent` tool: a `general-purpose` agent, or your own `reviewer-code` agent if you keep one. `model: opus`, `effort: high`, `run_in_background: false`. Description: `<ticket id> review round <N>`. Do not edit the checkout while a reviewer runs.
- When the ticket has a live UI or runtime leg, also start a second fresh reviewer in the same message, with the same settings, that audits the proof (your own `reviewer-test` agent if you keep one). Add each proof leg to its brief: how it was driven and the evidence path.

Round 1 brief:

```
Review only. Do not edit, commit, push, comment on PRs or start subagents.
Ticket: <id> Repo: <abs path> Base: <sha> Intent: <intent> Out of scope: <scope> Checks: <results>
Plan: {{VAULT_DIR}}/tickets/<id>/plan.md
See: git diff <base> [-- <paths>]; git status --short (read untracked files).
Read surrounding code. Find bugs, broken callers, mismatch with intent, breaches of a user ruling or a coding convention.
Skip style unless it hides a bug. Hold to the smallest change. Flag code, tests or guards the intent does not need. Other paths, rare cases, small perf, extra compat: nits.
blocker = the intended case is wrong. should = a real bug that callers will hit, or a breach of a user ruling or a coding convention. nit = the rest.
Reply. Line 1: VERDICT: APPROVE or VERDICT: CHANGES. Then one line for each finding, ids stable across rounds:
<S|T>1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion>
Use S for ids if you review the code. Use T if you audit the proof.
```

## 3. Answer findings

Check each finding and its severity yourself. Another path, a rare case or a small cost is a nit, whatever its label.

- Agree: a subagent makes the smallest fix. Prefer delete or narrow over a new lock, cache, helper or option. Fix the case that happened. Add one focused test that fails without the fix, if the intent needs it.
- Disagree: say why, with evidence (file:line, test, output).
- Out of scope or nit: decline in one line. List it as a follow-up in the report.
- Do not agree only to end the loop. Re-run the checks and `git diff --shortstat <base>`. If review made the diff larger, cut first.

## 4. Ledger

Append to `{{VAULT_DIR}}/tickets/<id>/review.md`. Create it with `type: ticket` frontmatter. One heading for each reviewer in each round:

```
## Round N - <reviewer>, <model>, <YYYY-MM-DD>
VERDICT: APPROVE | CHANGES
S1 fixed
S2 disagree: <evidence>
S3 declined: <reason>
```

## 5. Next round

Start one only if rounds remain and a blocker or should is open, behaviour code changed, or the approval does not cover the current behaviour diff. Send the round 1 brief, the ledger, the same base diff and the change since the last round. Tell the reviewer: open ids and changed code only. Mark each old id `resolved` or `still open: <reason>`.

## 6. Stop

- **Pass.** APPROVE on the current behaviour diff, no blocker or should open, no concern of your own.
- **Cap or dispute.** A blocker or should is open after round 3, or an item stays disputed after two replies. You rule. The user does not. An open blocker that is not fixed means scrap and plan again (push the branch first). A blocker cannot be dismissed. When only should items are open, you may move them to a follow-up ticket. Write both sides and your ruling in 2-3 lines each. The cap is not a pass.
- **Closed.** Use `closed` when each open item is fixed with its check run again and the rules for a next round ask for no new round, or when a should item stays disputed after two replies and you have evidence against it.
- **Ruling line.** Write one closing line after the last heading of the highest round in `review.md`, in one of three forms: `Ruling: scrap - <reason>`, `Ruling: follow-up <ticket id> - <reason>`, `Ruling: closed - <id>: fixed, <check that ran> | <id>: dismissed, <evidence>`.
- Do not push during the loop. After a pass, a `Ruling: follow-up` or a `Ruling: closed`, the change is ready for its draft PR. Open it when the user asks (root schema section 5), and add the note line `Reviewed: <N> rounds, <model>` (`{{VAULT_DIR}}/wiki/standards/pull-requests.md`).
- Report: rounds, model, what review changed, diff size before and after, fixed and declined findings with reasons.
