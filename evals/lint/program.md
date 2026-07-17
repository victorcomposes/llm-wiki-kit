# program.md — mutation strategy for the lint optimizer

The autoresearch equivalent of Karpathy's `program.md`: human-steered direction for
what kinds of edits the loop should try. The driver feeds the current error profile
(false negatives + false positives, aggregated over K runs) to a mutation agent, which
proposes a revised `SKILL.md`. This file shapes those proposals.

## The prime directive: generalise, don't memorise

Every edit must be a **general wording improvement** to the check's definition — one
that would help on any vault, not just this fixture. Forbidden: naming fixture pages,
services, or tickets in `SKILL.md` (e.g. "report only-logged as an orphan"). That is
overfitting; it raises the score and teaches the skill nothing. If a proposed edit only
makes sense because of a specific fixture file, reject it.

## Strategies, in rough priority

1. **Disambiguate overlapping checks.** When one fault can trip two checks, state which
   check owns it and that it is reported once. (Symptom: the same fault double-counted.)
2. **Scope the input precisely.** Say exactly what text a check reads — e.g. body prose
   vs YAML frontmatter relationship/`services:` arrays. (Symptom: metadata links
   mistaken for prose links.)
3. **Name the exceptions.** Where a definition has a carve-out, state it. E.g. orphan =
   unreachable by *navigation*; inbound links from append-only ledgers (`log.md`,
   `journal/*`, `brag.md`) don't count. (Symptom: ledger links rescuing orphans.)
4. **Add a worked example** to the check with the worst recall — one positive, one
   negative — so the boundary is unambiguous.
5. **Tighten, don't bloat.** Prefer sharpening an existing sentence over adding a
   paragraph. A longer skill is not a better skill.

## Guardrails

- Change only check definitions and their examples. Do not touch the report format,
  the log-append step, or the "reports only, never auto-fix" contract.
- One coherent set of edits per iteration, aimed at the current error profile.
- The metric is a proxy. The real target is a sharper, more general skill; the fixture
  only approximates that. Human review of the final diff is the backstop against
  overfitting (a held-out fixture would be the stronger fix — a Stage-3 idea).
