# LLM Wiki Kit

A portable installer for the Karpathy-style **LLM Wiki** — a persistent, interlinked Obsidian vault that an AI agent builds and maintains over time, plus the schema and skills that turn any agent into a disciplined wiki maintainer.

This kit is **agent-agnostic** (Claude Code and Codex/AGENTS.md) and **project-agnostic** (one project, or many service repos in one folder). You run it once per machine/workspace; an agent interviews you and stamps out the whole system tuned to your paths and ticket scheme.

## What's in the box

```
llm-wiki-kit/
├── README.md                      ← you are here
├── skills/setup-llm-wiki/SKILL.md ← the bootstrap skill (the brain of the installer)
└── templates/
    ├── schema/{CLAUDE.md, AGENTS.md}   ← root schema (Layer 3), placeholder-driven
    ├── vault/                          ← the Obsidian vault scaffold + bundled meta docs
    ├── hooks/                          ← enforcement hooks (capture/stop nudges,
    │                                      secret-scan, lint-reminder) + settings snippets
    └── skills/                         ← the 8 wiki skills, de-hardcoded:
        onboard · ticket · ingest · capture · query · journal · spark · lint
```

## Install (one time)

The whole point is that an agent does the work. But first the agent has to be able to *discover* the bootstrap skill — that's the only manual step.

**Claude Code:**

```powershell
# Windows / PowerShell — install the bootstrap skill globally
Copy-Item -Recurse -Force `
  ".\llm-wiki-kit\skills\setup-llm-wiki" `
  "$env:USERPROFILE\.claude\skills\setup-llm-wiki"
```

```bash
# macOS / Linux
mkdir -p ~/.claude/skills
cp -R ./llm-wiki-kit/skills/setup-llm-wiki ~/.claude/skills/
```

Keep the `llm-wiki-kit/templates/` folder somewhere the agent can read — the bootstrap skill copies from it.

**Codex / other agents:** point the agent at `skills/setup-llm-wiki/SKILL.md` and ask it to follow the procedure.

## Run

Start a fresh agent session and say:

> **"Set up the LLM wiki."**

The agent (via the `setup-llm-wiki` skill) will interview you — directory, single vs. multiple projects, global vs. project-level skill install, which agent(s), ticket prefix/tracker, builder-session module, enforcement hooks — then scaffold the vault, write the schema, and install the skills in dependency order. Finally it tells you to open a new session and run `/onboard`.

## Update

When the kit improves, say:

> **"Update the LLM wiki skills."**

The bootstrap runs in **Update mode**: it compares the `version:` of each installed skill against the kit, re-copies only what changed (preserving your vault content), and diffs the schema before touching it.

## The eight operations

| Skill | What it does |
|---|---|
| `onboard` | Orient at session start: read schema, list in-flight tickets, report what's blocking. |
| `ticket` | Scaffold a `<PREFIX>-NNNN` ticket workspace + feature branches. (Optional at install.) |
| `ingest` | Read a source (URL/file) and integrate it across 5–15 wiki pages. |
| `capture` | File substantive service knowledge learned this session into the durable folder-notes before the session ends. |
| `query` | Answer from the wiki with citations; file good answers back as pages. |
| `journal` | Append a session/day summary; capture brag-worthy wins. |
| `spark` | Mine the vault for prototype candidates for a recurring AI builder session. (Optional module at install.) |
| `lint` | Health-check: broken links, orphans, drift, contradictions. Reports only. |

## Companion skills (recommended, installed from upstream)

The kit deliberately does **not** vendor third-party skills — the installer offers them from their own repos so they stay updateable:

- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) — `obsidian-markdown`, `obsidian-cli`, `defuddle` (used by `/ingest` for URLs).
- [mattpocock/skills](https://github.com/mattpocock/skills) — `grill-me` (plan stress-testing), `handoff` (session handoff docs → ticket folders), `diagnose` (disciplined debugging; feeds `/capture` and the prototype-idea backlog), and `prototype` (the build step `/spark` hands off to, when the builder-session module is on).

## Hooks (optional, recommended — Claude Code only)

Without hooks everything still works, but knowledge capture is honor-system. With them, the standing rules are **enforced**. The installer offers four (`templates/hooks/`):

| Hook | Event / scope | What it does |
|---|---|---|
| `capture-nudge` | PostToolUse, user `settings.json` | After an edit in a service repo, nudges once per service per session to `/capture`; breadcrumbs which services were touched. |
| `stop-nudge` | Stop, user `settings.json` | Blocks session end once if a service was touched and capture hasn't run; otherwise nudges on uncommitted vault changes. |
| `secret-scan` | PreToolUse on `git`, vault `settings.json` | Blocks `git commit` while staged vault changes contain secret-shaped strings. |
| `lint-reminder` | SessionStart, vault `settings.json` | One-line tip when the last `/lint` is 7+ days old. |

Layout rule: **logic in the vault (versioned), pointers at user level (reach)** — `settings.json` doesn't cascade, so the two session-wide hooks must be referenced from `~/.claude/settings.json` (the installer merges, never overwrites). Windows uses the PowerShell nudge variants; macOS/Linux use the bash variants, which require `jq`. `secret-scan`/`lint-reminder` are bash everywhere (Git Bash on Windows). Hooks added mid-session activate only after `/hooks` is opened or a new session starts.

## Background

The pattern, primary sources, and design rationale are bundled at
`templates/vault/meta/llm-wiki.md` and `templates/vault/meta/obsidian-llm-wiki-blueprint.md`,
which the installer copies into every vault it creates.
