---
type: standard
date: {{TODAY}}
tags: [pull-requests, review]
---

# Pull requests

House rules for opening and updating a pull request. Root [[CLAUDE]] section 5 step 4 points here.

Adapt the mechanics to your host ({{TRACKER_NAME}}, GitHub, GitLab, Azure DevOps). The conventions below are host-independent; anything host-specific belongs in its own section at the bottom of this page, written once someone has been burned by it.

## Opening one

"Create a PR" means: push the branch, then open a **draft**. Publishing is the author's call, so reviewers are not notified until they say so. Do not open a PR unprompted at the end of implementation work; wait for the ask.

The body comes from the PR template **in the repo the branch lives in**. Worktrees carry their own copy, so never hardcode the path. The template is the only authority on structure: fill its sections, cut the ones that do not apply. Do not layer a second house style on top of it.

Order of work, every time:

1. Read the branch repo's template.
2. Write the body: one short "what does this PR do?" paragraph, the checklist, then two to four one-line notes. Deep rationale stays in the ticket and the vault, linked, never pasted.
3. Append whatever attribution footer the team has agreed on.
4. Create, then read the PR back and confirm the draft state and the description actually landed.

If the body needs more than about one screen to scan, it is too long. Most hosts cap the description server-side, so budget the footer's characters before trimming prose, not after.

## Writing the body

- **Open in product terms.** First sentence is a verb plus the user-visible things the PR delivers, plus the ticket ids. "Adds the settings page and shows out-of-scope records as visible but disabled", never "the user-facing half of workstream X". A reviewer cold on the workstream cannot parse workstream framing. Relationship to other PRs comes after, in its own short sentence.
- **Checklist.** `- [x] Item` means required and done. `- [ ] ~~Item~~ - none required.` means it does not apply. Never tick a box to mean "not applicable", and never leave a non-applicable item as bare unticked text. A tick claims work was done; an untouched empty box reads as work outstanding.
- **Notes are facts, not reasoning.** One line each: the fact a reviewer would otherwise flag, with no justification after it.
- **Beware `#N`.** Most hosts autolink `#<digits>` to the issue or work item with that id, in descriptions and in comments, often with no escape that survives the editor. Write "shot 1", "step 2", "set 3". Grep the body for `#[0-9]` before every write, including any PR-body file kept in the vault, since those are pasted verbatim.
- **Name deliberate pattern breaks.** When hand-rolled work deviates from the visible pattern of the surrounding code for a technical reason, say so in the notes with the reason, and surface it before review. Default to the visible pattern unless the reason is decisive; when it is, the trade-off call belongs to the reviewer, not the author.

## Comments

Reviewers open a PR cold, with none of the authoring session's context.

- Before posting, ask who reads this and whether they can act on it. A question only a data-source owner, another team or a product decision can answer goes to that person directly, never into the PR.
- An open item that genuinely belongs on the PR for context is phrased as a **statement**, not a question, and posted resolved or closed. An open thread from the author implies the reviewer owes a response.
- **A PR opens with zero outstanding threads.** Pattern-deviation notes included.
- On hosts where comments cannot be edited through the API, get it right first time. Never add a comment just to fix a typo.
- Strip internal-only references, vault ADR numbers and ticket shorthand from anything the team reads. See [[ai-style-guide]].

## What must never reach a pushed branch

A local-only hack stays uncommitted, or in a commit that is never pushed. Documenting one in the PR body is not a substitute for keeping it out.

- **Scan the diff before every push** for absolute paths and for `LOCAL-ONLY`, `TEMP` or `HACK` markers. If either is present, do not push.
- **Verify the way CI verifies**: full solution or workspace, release configuration, whole test suite. A filtered debug run is not evidence, and CI usually runs on a different OS than the author's machine.
- **A package dependency that has not merged means the PR cannot be green.** Land the dependency, take the published version, pin it, then raise the PR. Sequencing a cross-repo change is part of the work.
- **Placeholder ticket ids never appear in git or the host.** Placeholders are vault-only. Branches, commit subjects and PRs carry a real `{{TICKET_PREFIX}}` id; reusing the closest real ticket is allowed and preferred. Note the mapping in the placeholder's `state.md`.

## Updating an existing PR

An update call usually rewrites the draft state to whatever you pass, so passing "draft" out of habit can drag a published PR back to draft. Read the PR first and mirror its **current** state back. The value comes from the read, never from habit.

If that keeps happening, enforce it in a hook rather than in prose: deny the update unless a fresh single-use marker records a state that was actually read, and require an explicit override for a deliberate publish or unpublish.

## Host-specific

Nothing recorded yet. Add a section here the first time a host mechanic costs someone a round: attachment upload, description size caps, autolink behaviour, API gaps, whatever it turns out to be.

## Related

- [[CLAUDE]] section 5 step 4 - where this page is invoked from, and section 6 for commit and branch conventions.
- [[ai-style-guide]] - prose style, and the standing card for reporting the PR back.
