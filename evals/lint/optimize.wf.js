export const meta = {
  name: 'lint-optimize',
  description: 'Autoresearch-style loop: mutate lint/SKILL.md, eval against the fixture, keep only if mean F1 improves',
  phases: [
    { title: 'Bootstrap', detail: 'read current SKILL.md + baseline eval' },
    { title: 'Optimize', detail: 'propose edit -> eval K runs -> keep if better' },
  ],
}

// ---- fixed harness constants (the eval's prepare.py equivalent) ----
const FIXTURE = String((args && args.fixtureDir) || 'C:\\Projects\\llm-wiki-kit\\evals\\lint\\fixture')
const SKILL_PATH = String((args && args.skillPath) || 'C:\\Users\\victori.TRADESHIELD\\.claude\\skills\\lint\\SKILL.md')
const K = Number((args && args.K) || 3)
const MAX_ITERS = Number((args && args.maxIters) || 8)
const PATIENCE = 2

const MANIFEST = {
  scored_types: ['broken-wikilink', 'orphan', 'index-drift-missing', 'index-drift-dangling', 'missing-state', 'missing-service-page', 'graph-asymmetry'],
  excluded_types: ['stale-ticket', 'contradiction-unreviewed', 'suggested-concept', 'suggested-research-gap', 'kit-drift'],
  expected: [
    { type: 'broken-wikilink', source: 'wiki/concepts/alpha.md', target: 'nonexistent-alpha' },
    { type: 'broken-wikilink', source: 'wiki/services/Svc.A/Svc.A.md', target: 'ghost-page' },
    { type: 'orphan', page: 'wiki/concepts/orphan-concept.md' },
    { type: 'orphan', page: 'wiki/concepts/only-logged.md' },
    { type: 'index-drift-missing', page: 'wiki/concepts/beta.md' },
    { type: 'index-drift-missing', page: 'wiki/concepts/orphan-concept.md' },
    { type: 'index-drift-missing', page: 'wiki/concepts/only-logged.md' },
    { type: 'index-drift-dangling', entry: 'deleted-page' },
    { type: 'missing-state', folder: 'tickets/SD-9002' },
    { type: 'missing-service-page', service: 'Svc.Z' },
    { type: 'graph-asymmetry', from: 'Svc.A', to: 'Svc.B' },
  ],
}

const STRATEGY = `Prime directive: every edit is a GENERAL wording improvement to a check's definition, never a fixture-specific hack. Never name a specific page/service/ticket in SKILL.md — that is overfitting; reject such edits.
Strategies (priority order): (1) disambiguate overlapping checks — when one fault trips two checks, say which check owns it and that it is reported once; (2) scope inputs precisely — state whether a check reads body prose vs YAML frontmatter relationship/services arrays; (3) name exceptions — e.g. orphan = unreachable by navigation, so inbound links from append-only ledgers (log.md, journal/*, brag.md) don't count; (4) add one positive + one negative worked example to the worst-recall check; (5) tighten, don't bloat.
Guardrails: change only check definitions and their examples; never touch the report format, the log-append step, or the "reports only, never auto-fix" contract.`

const RUNNER = `You are running a vault health-check (lint). The lint PROCEDURE is below. Apply it EXACTLY as written — its wording is the thing under test; do not substitute your own idea of a check, follow the procedure's own definitions literally.
TARGET VAULT ROOT: ${FIXTURE}  (treat this as the vault root; ignore any absolute path hardcoded in the procedure). Read every .md file under it fully.
SCOPE: emit findings only for these seven types, mapping them to the procedure's checks; skip mtime-based stale/contradiction checks, advisory suggested-concept/research-gap heuristics, and kit-drift:
broken-wikilink(source,target), orphan(page), index-drift-missing(page), index-drift-dangling(entry), missing-state(folder), missing-service-page(service), graph-asymmetry(from,to).
Paths vault-relative, forward slashes.
--- BEGIN lint/SKILL.md ---
{{SKILL_MD}}
--- END lint/SKILL.md ---`

const FINDINGS_SCHEMA = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['type'],
    properties: { type: { type: 'string' }, source: { type: 'string' }, target: { type: 'string' }, page: { type: 'string' }, entry: { type: 'string' }, folder: { type: 'string' }, service: { type: 'string' }, from: { type: 'string' }, to: { type: 'string' } },
  } } },
}
const SKILL_SCHEMA = { type: 'object', required: ['skillMd', 'rationale'], properties: { skillMd: { type: 'string' }, rationale: { type: 'string' } } }

// ---- scorer (mirrors score.py canon()) ----
const pathN = v => String(v || '').replace(/\\/g, '/').trim().replace(/^\.\//, '').replace(/^\/+/, '').toLowerCase()
const nameN = v => String(v || '').trim().replace(/^\[+|\]+$/g, '').replace(/\.md$/, '').toLowerCase()
function canon(f) {
  const t = String(f.type || '').trim().toLowerCase()
  switch (t) {
    case 'broken-wikilink': return `broken-wikilink|${pathN(f.source)}|${nameN(f.target)}`
    case 'orphan': return `orphan|${pathN(f.page)}`
    case 'index-drift-missing': return `index-drift-missing|${pathN(f.page)}`
    case 'index-drift-dangling': return `index-drift-dangling|${nameN(f.entry)}`
    case 'missing-state': return `missing-state|${pathN(f.folder).replace(/\/+$/, '')}`
    case 'missing-service-page': return `missing-service-page|${nameN(f.service)}`
    case 'graph-asymmetry': return `graph-asymmetry|${[nameN(f.from), nameN(f.to)].sort().join('|')}`
    default: return null
  }
}
const scored = new Set(MANIFEST.scored_types), excluded = new Set(MANIFEST.excluded_types)
const EXPECTED = new Set(MANIFEST.expected.map(canon).filter(Boolean))
function score(findings) {
  const reported = new Set()
  for (const f of findings || []) {
    const t = String(f.type || '').trim().toLowerCase()
    if (excluded.has(t) || !scored.has(t)) continue
    const k = canon(f); if (k) reported.add(k)
  }
  const tp = [...EXPECTED].filter(k => reported.has(k))
  const fn = [...EXPECTED].filter(k => !reported.has(k))
  const fp = [...reported].filter(k => !EXPECTED.has(k))
  const p = (tp.length + fp.length) ? tp.length / (tp.length + fp.length) : 1
  const r = (tp.length + fn.length) ? tp.length / (tp.length + fn.length) : 1
  const f1 = (p + r) ? (2 * p * r) / (p + r) : 0
  return { f1, p, r, fn, fp }
}

// eval a candidate skill K times; return mean F1 + aggregated error profile
async function evalCandidate(skillMd, phase, tag) {
  const prompt = RUNNER.replace('{{SKILL_MD}}', skillMd)
  const runs = await parallel(Array.from({ length: K }, (_, i) => () =>
    agent(prompt, { label: `${tag}:run${i + 1}`, phase, schema: FINDINGS_SCHEMA })
      .then(o => score(o ? o.findings : []))))
  const ok = runs.filter(Boolean)
  const meanF1 = ok.reduce((s, x) => s + x.f1, 0) / (ok.length || 1)
  const tally = arrs => { const m = {}; arrs.flat().forEach(k => { m[k] = (m[k] || 0) + 1 }); return Object.entries(m).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k}  (${n}/${ok.length})`) }
  return { meanF1, fn: tally(ok.map(x => x.fn)), fp: tally(ok.map(x => x.fp)), perRun: ok.map(x => +x.f1.toFixed(4)) }
}

// ---- run ----
phase('Bootstrap')
const bootstrap = await agent(`Read the file at ${SKILL_PATH} and return its COMPLETE verbatim contents in the "skillMd" field. Set rationale to "bootstrap".`, { label: 'read-skill', phase: 'Bootstrap', schema: SKILL_SCHEMA })
let best = { skillMd: bootstrap.skillMd }
let bestEval = await evalCandidate(best.skillMd, 'Bootstrap', 'baseline')
log(`baseline mean F1 = ${bestEval.meanF1.toFixed(4)}  runs=[${bestEval.perRun}]  FN=${bestEval.fn.length} FP=${bestEval.fp.length}`)

phase('Optimize')
const trajectory = [{ iter: 0, meanF1: +bestEval.meanF1.toFixed(4), accepted: true, note: 'baseline' }]
let stale = 0
for (let iter = 1; iter <= MAX_ITERS; iter++) {
  if (bestEval.meanF1 >= 0.999) { log(`perfect score reached at iter ${iter - 1}; stopping`); break }
  if (stale >= PATIENCE) { log(`no improvement in ${PATIENCE} iters; stopping`); break }

  const errProfile = `False negatives (missed, should have reported):\n${bestEval.fn.join('\n') || '  (none)'}\n\nFalse positives (reported, should not have):\n${bestEval.fp.join('\n') || '  (none)'}`
  const mutPrompt = `You are improving a lint skill by editing its SKILL.md. Here is the strategy you must follow:\n${STRATEGY}\n\nCurrent SKILL.md:\n--- BEGIN ---\n${best.skillMd}\n--- END ---\n\nThe skill was evaluated against a fixture vault. Current mean F1 = ${bestEval.meanF1.toFixed(4)}. Error profile aggregated over ${K} runs:\n${errProfile}\n\nPropose a revised SKILL.md that fixes these errors through GENERAL wording improvements (never name a specific fixture page/service/ticket). Return the COMPLETE revised SKILL.md in "skillMd" and a one-line "rationale".`
  const cand = await agent(mutPrompt, { label: `mutate#${iter}`, phase: 'Optimize', schema: SKILL_SCHEMA })
  if (!cand || !cand.skillMd) { trajectory.push({ iter, meanF1: null, accepted: false, note: 'mutation failed' }); stale++; continue }

  const candEval = await evalCandidate(cand.skillMd, 'Optimize', `cand#${iter}`)
  const improved = candEval.meanF1 > bestEval.meanF1 + 0.0001
  trajectory.push({ iter, meanF1: +candEval.meanF1.toFixed(4), accepted: improved, rationale: cand.rationale, runs: candEval.perRun })
  log(`iter ${iter}: cand mean F1 = ${candEval.meanF1.toFixed(4)} vs best ${bestEval.meanF1.toFixed(4)} -> ${improved ? 'KEEP' : 'discard'}  (${cand.rationale})`)
  if (improved) { best = { skillMd: cand.skillMd }; bestEval = candEval; stale = 0 } else { stale++ }
}

return {
  baselineF1: trajectory[0].meanF1,
  bestF1: +bestEval.meanF1.toFixed(4),
  improved: bestEval.meanF1 > trajectory[0].meanF1 + 0.0001,
  remainingFN: bestEval.fn,
  remainingFP: bestEval.fp,
  trajectory,
  bestSkillMd: best.skillMd,
}
