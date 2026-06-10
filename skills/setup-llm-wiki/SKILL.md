---
name: setup-llm-wiki
version: 1.5.0
description: Bootstrap a Karpathy-style LLM Wiki (Obsidian vault + agent schema + the onboard/ticket/ingest/capture/query/journal/spark/lint skills, enforcement hooks, and companion-skill recommendations) into a directory of the user's choosing. Use when the user says "set up the LLM wiki", "set up an LM wiki", "install the wiki", "bootstrap a knowledge vault", "/setup-llm-wiki", "update the wiki skills", or asks any agent to stand up or upgrade the LLM-wiki system for one or many projects.
---

> **Two modes.** If the user says "update", "upgrade", or "refresh the skills" and a vault/schema already exists, run **Update mode** (see the end of this file) instead of the full bootstrap. Otherwise run the full interview + install below.

You are bootstrapping the **LLM Wiki** system for the user. This is the Karpathy "LLM Wiki" pattern: a persistent, interlinked Obsidian vault that an agent maintains over time, plus a schema file and a set of skills that turn any agent into a disciplined wiki maintainer.

Your job is to **interview the user, then stamp out the system from the bundled templates** — adapted to their directory, their project layout, their agent, and their ticket scheme. Work through this in order. Do not skip the interview; the answers fill placeholders in every file you write.

The templates live next to this skill at `../../templates/` relative to this `SKILL.md` (i.e. inside the `llm-wiki-kit/templates/` folder). If you cannot locate them, ask the user where they unpacked the kit.

---

## Step 0 — Locate the templates

Find the kit's `templates/` directory (sibling of the `skills/` folder this skill lives in). Confirm it contains `schema/`, `vault/`, and `skills/`. You will copy from here and substitute placeholders. If it is missing, stop and ask the user for the kit path.

---

## Step 1 — Interview the user

Ask these **one at a time**, in this order. For each, state your recommended default in parentheses and accept a one-word answer. Collect the answers into a config you will echo back before writing anything.

1. **Where should the wiki live?** Absolute path to the root directory (e.g. `C:\Dev` or `~/work`). This becomes `{{ROOT_DIR}}`. The vault itself will be created at `{{ROOT_DIR}}/.vault` → this is `{{VAULT_DIR}}`. *(Recommend: a directory that already contains, or will contain, the project(s) this wiki documents.)*

2. **Single project, or multiple services in one folder?** 
   - *Single* — the root is one project/repo; the wiki documents it alone.
   - *Multiple* — the root holds several service repos side by side; the wiki gets a `wiki/services/<Name>/<Name>.md` folder per repo (so each service can grow its own sub-pages).
   
   This decides whether you scaffold `wiki/services/` and whether onboard/ticket cross-reference service pages. *(Recommend: Multiple — costs nothing and the structure is identical; single-project users just end up with one service folder.)*

3. **If multiple:** auto-discover services now? *(Recommend: yes — present results, let the user curate.)* The discovery procedure:

   **Pass A — top-level signals** (immediate subdirectories of `{{ROOT_DIR}}`). Mark a folder a candidate if it contains any of:
   - `.git/` (any git repo)
   - `*.sln` or `*.slx` (a .NET solution at the top level)
   - `*.csproj`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod` (a single-project root)

   **Pass B — one-level-nested solutions** (for folders that are *containers* of multiple solutions — common in .NET layouts, e.g. `Acme/Acme.Billing/Foo.sln`, or a git repo whose `.git` lives at the top but whose actual solutions are one level deeper, e.g. `CompanyName/CompanyName.ProjectG/CompanyName.ProjectG.sln`). For **every** immediate subdirectory of `{{ROOT_DIR}}` (including ones that already matched Pass A — being a git repo doesn't mean it isn't *also* a container), look one level deeper for any of the same markers. If a Pass-A folder has ≥ 2 nested matches, treat it as a container too and offer single-page vs page-per-nested in Step 3b. A folder with `.git` at the top and zero nested solutions is a normal single-project repo (no container handling).

   **Present results to the user as a grouped, checkable list**, e.g.:
   ```
   Found under {{ROOT_DIR}}:
     [x] Project.A                 (git repo, 1 .sln)
     [x] Project.B                 (git repo)
	     [ ] Project.C             (git repo)
     [x] CompanyName               (container/folder — 3 nested solutions)
         ├ CompanyName.ProjectG       (git repo)
         ├ CompanyName.ProjectF       (git repo)
         └ CompanyName.ProjectH       (git repo)
   ```
   Then ask, in order:
   - **3a — Curate the top-level list.** "Tick/untick which of the above to include as wiki services." Default: every git repo ticked, every container ticked, anything that looks like a vendor/archive folder unticked.
   - **3b — Container handling.** For each ticked container: "One parent page covering all nested projects, or one page per nested project?" *(Recommend: one page per nested project for .NET solutions — each solution is its own deployable surface area.)*
   - **3c — Anything missed?** "Any subprojects without `.git`/`.sln` markers (monorepo packages, scripts directories) that should also get a service page? Type names, or `none`."

   The final list — top-level repos + chosen nested projects + user additions — becomes the set of `wiki/services/<Name>/<Name>.md` folder-note stubs to create. Each service is a folder so it can grow extra pages (`architecture.md`, `dependencies.md`, diagrams in `_assets/`) without restructuring later. The main file inside is named after the service (the "folder note" pattern) so `[[<Name>]]` wikilinks resolve to it natively.

4. **Install the skills globally or per-project?**
   - *Global* — `~/.claude/skills/` (Claude Code) — available in every session on this machine.
   - *Project* — `{{ROOT_DIR}}/.claude/skills/` — committed alongside the code, travels with the repo.
   
   *(Recommend: Global for a personal knowledge vault; Project when the wiki ships with a shared repo.)*

5. **Which agent(s) will maintain the wiki?** One or both of:
   - *Claude Code* → write the schema to `{{ROOT_DIR}}/CLAUDE.md`.
   - *Codex / AGENTS.md-aware tools* → also write `{{ROOT_DIR}}/AGENTS.md`.
   
   Both files carry the same conventions; AGENTS.md is the portable mirror. *(Recommend: whichever the user actually runs; default Claude Code.)*

6. **Ticket tracking?** Enable the `ticket` skill?
   - If **yes**: ask for the **ticket prefix** (e.g. `SD`, `PROJ`, `JIRA`) → `{{TICKET_PREFIX}}`, and optionally the **tracker name + base URL** (e.g. `JIRA`, `https://acme.atlassian.net/browse/`) → `{{TRACKER_NAME}}` / `{{TRACKER_URL}}`. The ticket skill will validate identifiers as `{{TICKET_PREFIX}}-\d+`.
   - If **no**: skip the `ticket` skill entirely and omit the tickets section from the schema.
   *(Recommend: enable with a sensible prefix — it's the spine of the onboard briefing.)*

7. **Builder-session module?** Does the team run a recurring AI prototyping/builder session (rapid, ambitious, non-BAU builds)?
   - If **yes**: install the `spark` skill, scaffold `wiki/concepts/prototype-ideas.md` from the template, and keep the two "prototype seeds" standing rules in the schemas. Ask for the session cadence/length if the user volunteers it (used only in the prototype-ideas page prose).
   - If **no**: skip `spark`, skip the prototype-ideas page, and delete the seed-rule bullets (marked "builder-session module") from every schema template before writing.
   *(Recommend: yes if the team has any hack-day/innovation-time ritual; easy to add later via Update mode otherwise.)*

8. **Enforcement hooks?** *(Claude Code only — skip and record "no" if the user chose Codex only.)* Install the four hooks that turn standing rules into enforced behaviour?
   - **capture-nudge** (PostToolUse, user scope) — after an edit in a service repo, nudges once per service per session to `/capture`; drops the breadcrumb `capture` reads.
   - **stop-nudge** (Stop, user scope) — blocks session end once if a service was touched and capture hasn't run; otherwise nudges on uncommitted vault changes.
   - **secret-scan** (PreToolUse on `git`, vault scope) — blocks `git commit` while staged vault changes contain secret-shaped strings.
   - **lint-reminder** (SessionStart, vault scope) — one-line tip when the last `/lint` is 7+ days old.

   On macOS/Linux the two nudge hooks require `jq` on PATH — check with `command -v jq` and tell the user if it's missing. *(Recommend: yes — without these, capture is honor-system.)*

After the interview, **echo the full config back** as a short table (root, vault, layout, skill scope, agent(s), tickets/prefix/tracker, builder-session module, hooks) and ask the user to confirm before you write any files.

---

## Step 2 — Resolve placeholders

Build the substitution map from the answers. Every template file uses double-brace placeholders:

| Placeholder | Filled with |
|---|---|
| `{{ROOT_DIR}}` | the root path (Step 1.1) |
| `{{VAULT_DIR}}` | `{{ROOT_DIR}}/.vault` |
| `{{TICKET_PREFIX}}` | e.g. `SD` (or blank if tickets disabled) |
| `{{TRACKER_NAME}}` | e.g. `JIRA` (or blank) |
| `{{TRACKER_URL}}` | tracker base URL (or blank) |
| `{{TODAY}}` | today's date, `YYYY-MM-DD`, from the user's context |

Use the user's native path style (backslashes on Windows, forward slashes elsewhere) consistently in every file you write. Detect the OS from the environment.

---

## Step 3 — Scaffold the vault

Create `{{VAULT_DIR}}` and copy the `templates/vault/` tree into it, substituting placeholders as you go. The structure:

```
{{VAULT_DIR}}/
├── README.md
├── meta/
│   ├── llm-wiki.md                  # the canonical Karpathy idea file (copied verbatim)
│   └── obsidian-llm-wiki-blueprint.md
├── wiki/
│   ├── index.md                     # the catalogue (seeded, mostly empty)
│   ├── log.md                       # append-only ledger (one bootstrap entry)
│   ├── brag.md
│   ├── journal/                     # YYYY-MM.md created on first /journal
│   ├── services/                    # one page per repo (if "multiple")
│   ├── concepts/
│   ├── incidents/
│   ├── runbooks/
│   ├── standards/
│   └── _assets/
└── tickets/                         # only if tickets enabled
```

- Copy `templates/vault/CLAUDE.md` to `{{VAULT_DIR}}/CLAUDE.md` (the **vault root**, not `wiki/_assets/`), substituting `{{ROOT_DIR}}` / `{{VAULT_DIR}}` / `{{TICKET_PREFIX}}`. This is the vault-scoped agent schema (auto-loads when cwd is inside the vault). It lives at the vault root so it isn't an orphan inside the wiki and is unambiguous to agents.
- If the builder-session module is enabled (Step 1.7): copy `templates/vault/wiki/concepts/prototype-ideas.md` to `{{VAULT_DIR}}/wiki/concepts/prototype-ideas.md` and list it under `## Concepts` in `wiki/index.md`. Remind the user to replace the placeholder session brief with their team's own.
- Copy `templates/vault/wiki/concepts/service-graph.md` to `{{VAULT_DIR}}/wiki/concepts/service-graph.md`. This is the rolled-up view of all service relationships — the file starts empty (no edges declared yet) but is created at bootstrap so the schema's references to `[[service-graph]]` resolve immediately. The agent fills it as soon as service relationship frontmatter is populated. List it under `## Concepts` in `wiki/index.md`.
- For **multiple-services**: use the final curated list from Step 1.3. Before writing, **echo the final list back to the user** as `wiki/services/<Name>/<Name>.md → <source path under {{ROOT_DIR}}>` and ask for confirmation. On confirm, for each service create:
  - The folder `wiki/services/<Name>/`
  - The folder note `wiki/services/<Name>/<Name>.md` with frontmatter:
    ```yaml
    ---
    type: service
    service: <Name>
    path: <source path under {{ROOT_DIR}}>
    date: {{TODAY}}
    tags: []
    calls: []
    depends_on: []
    emits_events_to: []
    subscribes_to: []
    ---
    ```
    and a stub body containing the section skeleton: `## Overview` (one-line "TODO: describe"), `## Architecture`, `## Build & Test`, `## Relationships` (one line: *"Populate this as the four relationship arrays above grow — explain the why and the failure mode for each non-obvious edge."*), `## Owners`, `## Related tickets`. Leave each section empty for the agent to fill on first `/ingest`.

  List each service under a `## Services` heading in `wiki/index.md` as `[[<Name>]]` (which resolves to `<Name>/<Name>.md` natively).

  For nested projects from a container, flatten to `<container>.<project>` as the service name (e.g. `CompanyName.ProjectG/CompanyName.ProjectG.md`). This keeps the folder name unique and the wikilink unambiguous.
- For **single project**, create one folder `wiki/services/<root-basename>/<root-basename>.md` with the same skeleton.
- Seed `log.md` with: `## [<today>] bootstrap | LLM Wiki scaffolded at {{VAULT_DIR}}`.
- Initialise a git repo in `{{VAULT_DIR}}` and make the first commit (`vault: bootstrap`). Add a `.gitignore` for `.obsidian/workspace*.json`.

---

## Step 4 — Write the schema (Layer 3)

From `templates/schema/`:

- Always write `CLAUDE.md` to `{{ROOT_DIR}}/CLAUDE.md` if Claude Code was chosen.
- Also write `AGENTS.md` to `{{ROOT_DIR}}/AGENTS.md` if Codex was chosen.

Substitute placeholders. If tickets are disabled, delete the `## Tickets` section from the schema before writing. If a schema file already exists at the destination, **do not overwrite** — show the user a diff and ask whether to merge or append a clearly-marked LLM-Wiki section.

---

## Step 5 — Install the skills, in dependency order

Copy each skill directory from `templates/skills/` to the chosen scope (`~/.claude/skills/<name>/` for global, `{{ROOT_DIR}}/.claude/skills/<name>/` for project), substituting placeholders in each `SKILL.md`. **Install in this order** — later skills reference earlier ones, and this is the order they matter to a new user:

1. **onboard** — the entry point; every fresh session starts here.
2. **ticket** — *(skip if tickets disabled)* scaffolds work items.
3. **ingest** — the core wiki-building operation.
4. **capture** — end-of-session knowledge filing; the schema's capture standing rule made explicit.
5. **query** — answer questions from the wiki and file good answers back as pages.
6. **journal** — daily/session record.
7. **spark** — *(skip if builder-session module disabled)* mines the vault for prototype candidates.
8. **lint** — health-check; depends on the others having produced content.

---

## Step 5b — Install the hooks (if enabled in Step 1.8)

Hooks follow the layout rule: **logic in the vault (versioned), pointers at user level (reach)**. `settings.json` does NOT cascade up the directory tree — a vault-level hook only fires in vault sessions — so the two hooks that must fire in *every* session under `{{ROOT_DIR}}` (capture-nudge, stop-nudge) are referenced from `~/.claude/settings.json`, while the vault-only hooks (secret-scan, lint-reminder) live in `{{VAULT_DIR}}/.claude/settings.json`.

1. **Copy the scripts** from `templates/hooks/` to `{{VAULT_DIR}}/.claude/hooks/`, substituting placeholders:
   - Windows: `capture-nudge.ps1`, `stop-nudge.ps1` (native backslash paths inside) + `secret-scan.sh`, `lint-reminder.sh` (forward-slash paths — they run under Git Bash).
   - macOS/Linux: `capture-nudge.sh`, `stop-nudge.sh`, `secret-scan.sh`, `lint-reminder.sh` (all forward-slash). Run `chmod +x` on them.
   - In `.sh` files **always** substitute `{{ROOT_DIR}}`/`{{VAULT_DIR}}` with forward-slash paths, even on Windows.
2. **Write the vault-scope settings**: copy `templates/hooks/vault-settings.json` to `{{VAULT_DIR}}/.claude/settings.json` (substituted). If the file already exists, merge the `hooks` entries instead of overwriting.
3. **Merge the user-scope entries** from `user-settings-hooks.windows.json` or `.posix.json` (per OS) into `~/.claude/settings.json`. **Never overwrite this file** — it holds the user's model/theme/other hooks. Read it, merge the `PostToolUse` and `Stop` entries into the existing `hooks` object (create it if absent), drop the `"//"` comment key, show the user the resulting diff, and write only on confirmation. If the user already has a Stop hook, append ours as an additional entry rather than replacing theirs.
4. **Tell the user the activation gotcha**: hooks added mid-session don't fire until `/hooks` is opened or a new session starts.
5. The vault-scope files are versioned — they'll be picked up by the vault's first commit.

If hooks were declined, tell the user the trade-off in one line: `capture` runs on demand only, and the schema's standing rule is the sole reminder.

Each `SKILL.md` carries a `version:` field. Record the installed version set so Update mode can tell what's stale.

Preserve directory names exactly (they must match the `name:` in frontmatter). Do not flatten bundled resources. After copying, list what you installed and where.

---

## Step 5c — Companion skills (optional, recommended)

These are **third-party skills the kit recommends but does not vendor** — they're maintained upstream, so installing from source keeps them updateable and keeps the kit honest about what it owns. Offer each install; respect a "no". Install to the same scope chosen in Step 1.4.

1. **Obsidian skills** — `npx skills add https://github.com/kepano/obsidian-skills` from inside the vault adds `obsidian-markdown`, `obsidian-cli`, `defuddle` (used by `/ingest` for URLs), etc.
2. **From `https://github.com/mattpocock/skills`** (install via `npx skills add` pointed at the repo, or copy the individual skill folders):
   - **`grill-me`** (productivity) — stress-test a plan by interviewing the user; referenced by the wiki workflow for plan reviews.
   - **`handoff`** (productivity) — compact a session into a handoff doc for the next agent; pairs with ticket folders (file the doc into `tickets/<id>/notes.md`).
   - **`diagnose`** (engineering) — disciplined diagnosis loop; every minimised repro and root cause it produces is `/capture` and prototype-seed fuel.
   - **`prototype`** (engineering) — *recommend only if the builder-session module is enabled*: it's the natural hand-off target after `/spark` picks a candidate.
   - Do **not** recommend `grill-with-docs` or `improve-codebase-architecture` here — they write to `CONTEXT.md`/`docs/adr/`, a parallel knowledge store that competes with the vault as source of truth.

Companion skills are outside Update mode's version tracking — they update from their own upstream.

Recommend the user install these **Obsidian plugins** from inside Obsidian (Settings → Community plugins → Browse):

- **Obsidian Git** — auto-commits while Obsidian is open. Worth enabling immediately on a fresh vault.

---

## Step 6 — Verify

- Confirm each skill's `SKILL.md` exists at its destination with intact frontmatter.
- Confirm the schema file(s) exist and contain no leftover `{{...}}` placeholders (grep for `{{` — there should be zero hits in everything you wrote).
- Confirm `{{VAULT_DIR}}/wiki/index.md` and `log.md` exist.
- Tell the user: **start a fresh agent session in `{{ROOT_DIR}}` and run `/onboard`** (skills register at session start, so the current session won't see them yet).

---

## Step 7 — Report and hand off

Give the user a concise summary:
- Where the vault lives and what's in it.
- Which schema file(s) were written.
- Which skills were installed, in what scope, and the order.
- The ticket prefix in effect (or that tickets are off).
- Next actions: open the vault in Obsidian, run `/onboard` in a new session, then `/ingest <url-or-path>` to fold in the first source.

Do not start ingesting or doing real work — bootstrapping is done once the system stands up and verifies. Hand control back to the user.

---

## Update mode

Use this when the system already exists and the user wants the latest skills/schema without re-scaffolding the vault.

1. **Locate the existing install.** Find the vault (`.vault` under the root, or ask) and the skills scope (global `~/.claude/skills` and/or project `.claude/skills`). Read the config back from the existing schema file — `{{ROOT_DIR}}`, `{{TICKET_PREFIX}}`, tracker, single/multiple — so you don't re-interview. Confirm the inferred config with the user in one line.
2. **Compare versions.** For each kit skill, read the `version:` in `templates/skills/<name>/SKILL.md` vs the installed copy. List which are new, which are newer, which are unchanged.
3. **Copy only what changed**, substituting the existing config's placeholders. Preserve directory names. Show the user the version delta per skill before writing.
4. **Schema:** if the kit's schema template is newer, show a diff against the installed `CLAUDE.md`/`AGENTS.md` and ask before applying — the user may have hand-edited it. Never blind-overwrite a schema.
5. **Hooks:** if the install has hooks (`{{VAULT_DIR}}/.claude/hooks/` exists), diff each installed script against its kit template (placeholder-substituted) — scripts carry no `version:` field, so compare content. Show changed scripts and ask before overwriting; the user may have local tweaks. Settings files: only re-merge if the kit's hook *entries* changed.
6. **Never touch the vault content** (`wiki/`, `tickets/`, `journal/`) in Update mode — only skills, hooks, and (with consent) the schema.
7. **Report** the version transitions (`onboard 1.0.0 → 1.1.0`, …) and append a `## [<today>] update | skills <old>→<new>` line to `{{VAULT_DIR}}/wiki/log.md`. Remind the user to start a fresh session for re-registration.
