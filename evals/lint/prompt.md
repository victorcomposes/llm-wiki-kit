# Lint eval runner prompt (thin harness)

This wraps the **candidate `lint/SKILL.md`** (the mutable target) and runs it against
the fixture vault. It is deliberately **thin**: it does NOT restate any check
semantics. All check logic comes from the spliced-in SKILL.md. If this file described
the checks itself, mutating SKILL.md would change nothing measurable — you'd be
scoring the wrapper. The only things fixed here are the target directory, the scope of
which findings to emit, and the output format.

---

You are running a vault health-check. The lint procedure is spliced in at the bottom.
Apply it exactly as written — its wording is the thing under test. Do not substitute
your own idea of what each check should do; follow the procedure's own definitions.

**Target vault root:** the directory passed to you (the fixture). Treat THAT as the
vault root. Ignore any absolute path (e.g. `C:\Dev\.vault`) hardcoded in the
procedure — it names the real vault, not this run. Read every `.md` file under the
target fully before deciding.

**Scope:** emit findings only for these seven check types (map them to the
corresponding checks in the procedure). Skip everything else the procedure lists —
mtime-based stale/contradiction checks, advisory "suggested concept/research gap"
heuristics, and kit-drift — none of those are in scope.

- `broken-wikilink`  (source, target)
- `orphan`  (page)
- `index-drift-missing`  (page)
- `index-drift-dangling`  (entry)
- `missing-state`  (folder)
- `missing-service-page`  (service)
- `graph-asymmetry`  (from, to)

**Output:** your ENTIRE final message is a single JSON array, nothing else — no prose,
no markdown fences. One object per finding, keys as named above, paths vault-relative
with forward slashes. Example shape (NOT the answer — your findings will differ):

```json
[{"type":"broken-wikilink","source":"wiki/foo.md","target":"bar"},
 {"type":"orphan","page":"wiki/baz.md"}]
```

--- BEGIN CANDIDATE lint/SKILL.md ---
{{SKILL_MD}}
--- END CANDIDATE lint/SKILL.md ---
