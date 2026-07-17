#!/usr/bin/env python3
"""Score a lint run against the fixture manifest.

Usage:  python score.py findings.json [manifest.json]

findings.json is a JSON array of objects, each with a "type" and the
type-specific keys the manifest uses (see manifest.json "expected").
The metric is F1 over the scored types. Reported findings whose type is
excluded (mtime/advisory/env checks) are dropped: neither rewarded nor
penalised. Findings of a scored type that aren't in the manifest count
against precision — over-reporting is not free.

Self-check: run with no args to score a built-in perfect/noisy sample.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent


def canon(finding: dict):  # canonical (type, key) string; unmatchable -> None
    t = str(finding.get("type", "")).strip().lower()

    def path(v):
        return str(v or "").replace("\\", "/").strip().lstrip("./").lstrip("/").lower()

    def name(v):
        return str(v or "").strip().strip("[]").removesuffix(".md").lower()

    if t == "broken-wikilink":
        return f"broken-wikilink|{path(finding.get('source'))}|{name(finding.get('target'))}"
    if t == "orphan":
        return f"orphan|{path(finding.get('page'))}"
    if t == "index-drift-missing":
        return f"index-drift-missing|{path(finding.get('page'))}"
    if t == "index-drift-dangling":
        return f"index-drift-dangling|{name(finding.get('entry'))}"
    if t == "missing-state":
        return f"missing-state|{path(finding.get('folder')).rstrip('/')}"
    if t == "missing-service-page":
        return f"missing-service-page|{name(finding.get('service'))}"
    if t == "graph-asymmetry":
        a, b = sorted([name(finding.get("from")), name(finding.get("to"))])
        return f"graph-asymmetry|{a}|{b}"
    return None  # unknown / excluded type


def score(findings, manifest):
    scored = set(manifest["scored_types"])
    excluded = set(manifest["excluded_types"])
    expected = {canon(f) for f in manifest["expected"]}
    expected.discard(None)

    reported = set()
    for f in findings:
        t = str(f.get("type", "")).strip().lower()
        if t in excluded:
            continue  # neither reward nor penalise
        if t not in scored:
            continue  # unknown type, ignore
        k = canon(f)
        if k:
            reported.add(k)

    tp = sorted(expected & reported)
    fn = sorted(expected - reported)
    fp = sorted(reported - expected)
    p = len(tp) / (len(tp) + len(fp)) if (tp or fp) else 1.0
    r = len(tp) / (len(tp) + len(fn)) if (tp or fn) else 1.0
    f1 = 2 * p * r / (p + r) if (p + r) else 0.0
    return {
        "tp": len(tp), "fp": len(fp), "fn": len(fn),
        "precision": round(p, 4), "recall": round(r, 4), "f1": round(f1, 4),
        "false_negatives": fn, "false_positives": fp,
    }


def _selfcheck():
    m = json.loads((HERE / "manifest.json").read_text())
    perfect = m["expected"]
    assert score(perfect, m)["f1"] == 1.0, "perfect run must score 1.0"
    noisy = perfect + [{"type": "orphan", "page": "wiki/concepts/alpha.md"}]
    assert score(noisy, m)["precision"] < 1.0, "false positive must dent precision"
    excluded_ok = perfect + [{"type": "stale-ticket", "folder": "tickets/SD-9001"}]
    assert score(excluded_ok, m)["f1"] == 1.0, "excluded type must not be penalised"
    missing = perfect[:-1]
    assert score(missing, m)["recall"] < 1.0, "a miss must dent recall"
    print("selfcheck ok")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        _selfcheck()
        sys.exit(0)
    manifest = json.loads(Path(sys.argv[2] if len(sys.argv) > 2 else HERE / "manifest.json").read_text())
    findings = json.loads(Path(sys.argv[1]).read_text())
    print(json.dumps(score(findings, manifest), indent=2))
