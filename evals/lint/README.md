# lint eval harness

An autoresearch-style optimization harness for the `lint` skill. Karpathy's
[autoresearch](https://github.com/karpathy/autoresearch) loops an agent over a
fixed harness (`prepare.py`) + a mutable target (`train.py`) scored by one metric
(`val_bpb`). This ports that shape to a *skill*, because a skill's behaviour is the
one thing in this vault with a genuinely countable metric.

| autoresearch | here |
|---|---|
| `prepare.py` (fixed harness) | `fixture/` + `manifest.json` + `score.py` + `prompt.md` |
| `train.py` (mutable target) | `lint/SKILL.md` |
| `val_bpb` (metric, lower better) | **F1** over planted defects (higher better) |
| 5-min wall clock (comparability) | fixed fixture + average of K runs |

## Files

- `fixture/` — a self-contained mini-vault with a known set of planted defects.
- `manifest.json` — ground truth: every expected finding. The scored types, and the
  checks deliberately left out, are documented inline.
- `score.py` — diffs a run's findings against the manifest → precision / recall / F1.
  Stdlib only. Run with no args for a self-check.
- `prompt.md` — the fixed runner wrapper; splices a candidate `SKILL.md` in and pins
  the JSON output format so the scorer reads a clean signal.
- `baseline/` — the current-skill baseline runs (see below).

## Metric

F1 over seven **countable** check types: broken-wikilink, orphan, index-drift-missing,
index-drift-dangling, missing-state, missing-service-page, graph-asymmetry.

Deliberately **out of scope** (documented in `manifest.json`): mtime-based checks
(stale tickets, unreviewed contradictions) are not reproducible from a git checkout;
advisory heuristics (suggested concepts/research gaps) aren't defects; kit-drift is
environment-specific. A loop optimizing this metric cannot see those checks, so it
can't regress them either — keep them in mind when editing the skill.

## How to run

1. For each of K runs, hand a fresh agent the `prompt.md` wrapper with the candidate
   `lint/SKILL.md` spliced into `{{SKILL_MD}}`, pointed at `fixture/` as the vault root.
   It returns a JSON array of findings.
2. `python score.py run.json` for each; average the F1 across runs.

## Baseline — lint v1.3.0

3 runs, identical output. **F1 = 0.947** (precision 1.0, recall 0.90). Zero variance.

The metric is stable, so a future optimization loop would track signal, not noise.

One consistent miss (the only false negative): a dangling index entry
(`[[deleted-page]]` in `index.md`) is reported as `index-drift-dangling` but **not
also** as a `broken-wikilink`. Check #1 says every wikilink in every `.md` file is in
scope, so by the letter it should appear under both. The skill dedupes it into one
bucket. That is the headroom a Stage-2 loop would close — or the signal to decide the
manifest is over-strict and drop that expected finding. Either way, the harness did
its job: it turned a vague "is lint good?" into a number and a specific, reproducible
gap.

## Stage 2 — the loop (built)

- `program.md` — human-steered mutation strategy (generalise, don't memorise).
- `optimize.wf.js` — the driver Workflow. Reads the current `SKILL.md`, then loops:
  mutation agent proposes an edit guided by `program.md` + the live error profile →
  eval K=3 → keep only if mean F1 improves. Stops at F1=1.0 or 2 stale rounds.
  Scoring is reimplemented in-script (mirrors `score.py`) since Workflow scripts have
  no filesystem access. Run:
  `Workflow({scriptPath: ".../optimize.wf.js", args: {fixtureDir, skillPath, K, maxIters}})`.
- The winning `SKILL.md` is returned, never auto-installed — review the diff, then
  install + bump version + port to the kit template by hand.

### First run (lint v1.3.0 → v1.4.0)

Baseline mean F1 0.910 → **1.0 in one iteration**, converged (2 stale rounds, halted).
The edit: check 1 reads body prose only and defers overlapping faults to their owning
checks (5/6/8); check 2 excludes ledger inbounds from orphan tallying. Winner saved as
`candidate-SKILL.md`; shipped as lint v1.4.0.

Known ceiling: the fixture is a proxy, so the loop rediscovers the intent encoded in
the manifest rather than inventing new insight, and can overfit. `program.md`'s
"don't name fixture files" rule + human diff review are the guard. A held-out second
fixture is the stronger fix (Stage 3).
