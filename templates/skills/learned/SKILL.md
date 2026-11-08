---
name: learned
version: 1.0.2
description: Send general learnings from the work vault to a separate personal vault inbox, one way, with a leak check. Use when the user says "learned", "/learned", "send learnings to my personal vault", or "promote learnings". The /journal skill calls it after the brag step. Installed only when a personal vault is configured.
---

One-way pipe. Work vault (`{{VAULT_DIR}}`) to personal vault (`{{PERSONAL_VAULT}}`). Nothing flows back.

If `{{PERSONAL_VAULT}}` is `none` or is not an existing folder, do nothing and say nothing. This is not an error.

## The hard rule

Employer data never reaches the personal vault. The personal vault may be synced or pushed to a remote. Check whether it has an auto-commit plugin or job, because anything you copy in can leave the machine soon after. The leak check in step 5 is the only gate.

Selection test for each candidate: "Would the user keep this note if they left their employer tomorrow?" Only general knowledge passes.

Write every note in general terms:
- No employer, client, partner, product, service, system or colleague names.
- No ticket ids ({{TICKET_PREFIX}}-NNNN or placeholders), no customer numbers, no PR numbers.
- No code, SQL, config or URLs from work repos.
- Use a neutral invented example. Do not disguise a real case.

## Steps

1. **Read sources.**
   - `{{VAULT_DIR}}/wiki/log.md` entries after the last `] learned |` entry. If there is none, use the last 7 days. Run `date` first.
   - Today's entry (`## YYYY-MM-DD`) in `{{VAULT_DIR}}/wiki/journal/YYYY-MM.md`, if it exists.
   - The current session.
2. **Pick candidates.** Apply the selection test. Keep an idea only if it is general, durable and stands alone. One idea per candidate. Zero is a valid result. If there are none, say so, append the log line with `0 notes` (step 8) so the window moves on, and stop.
3. **Dedupe.** Search the personal vault's notes, slips and inbox folders for the same concept. If the concept exists, do not duplicate it. Write the new note only for what is new, and put `Extends [[Existing note title]]` as the first line of the body. If the existing note already covers it, drop the candidate.
4. **Draft.** Read the personal vault's knowledge note template (look under its templates folder; ask once if unclear). The drafts folder is `{{VAULT_DIR}}/.learned-drafts/`. Make sure `{{VAULT_DIR}}/.gitignore` lists `.learned-drafts/` (add the line if it is missing). Clear the folder first: `Glob` `*` in it, then delete each file, or if the shell is not allowed, overwrite each file with `Write` and the single word `cleared`. Ignore any file that holds only `cleared`. For each candidate write one note there. Then write `_names.txt` there, one draft file name per line.
   - File name in the style of the existing notes: `Concept - one-line meaning.md`. Do not use `: ? " / \ * < > |`.
   - Frontmatter exactly as the template has it.
   - Body sections: `## TL;DR` (2 or 3 bullets), `## WHAT THIS IS`, `## WHEN THIS MATTERS`, `## EXAMPLE` (neutral and invented).
   - Plain short sentences.
5. **Leak check before anything touches the personal vault.** Use only the built-in file tools (`Read`, `Glob`, `Grep`). Do not use a shell. Build one regex, then search the drafts:
   1. `Read` `deny.txt` in this skill's folder. Drop lines that start with `#` and blank lines. Each other line is one case-insensitive regex (`\b` around short words). The user extends this file.
   2. `Glob` `*` with path `{{VAULT_DIR}}/wiki/services`. The folder names are the first path segment after `services`. Skip a path with no further segment, because that is a file. Escape each `.` as `\.`.
   3. Add the ticket id shapes: `{{TICKET_PREFIX}}-\d+` and `VLT-\d+`.
   4. Join all parts with `|` into one line.
   5. Call `Grep` with `pattern` set to that regex, `path` set to `{{VAULT_DIR}}/.learned-drafts/`, `-i` true and `output_mode` `content`. It covers every draft, `_names.txt` (the file names) and the career evidence draft from step 7.
   - No match is a pass.
   - Any match: rewrite the draft in general terms, then run the whole check again. Delete a failing draft, or overwrite it with `cleared`. Never copy a failing draft.
   - Also read each draft once. The deny list cannot know a name it has not seen. If you see a proprietary term, rewrite the draft and add the term to `deny.txt`.
6. **Copy.** Copy only passing drafts into the personal vault's inbox folder. Do not overwrite an existing file: if the name exists, stop and treat it as a dedupe hit. The user reviews the notes and moves them to the notes folder. Run the step 5 `Grep` once more with `path` set to each copied file, one call per file. Do not search the whole inbox, because it holds other notes. Do not copy `_names.txt` or the career evidence draft.
7. **Career evidence.** If the session or today's journal added lines to `wiki/brag.md` or `wiki/journal/evidence-log.md`, write a scrubbed version of each. Keep the category. Write the scrubbed lines to `{{VAULT_DIR}}/.learned-drafts/career-evidence.md` and run the step 5 `Grep` over the drafts folder. Append only passing lines as dated bullets to `Career/Career evidence.md` in the personal vault (create the `Career` folder and the file on first use if missing, with the template's frontmatter and a `# Career evidence` heading):
   `- YYYY-MM-DD · <category> · **<title>** - <what was done and the result, in general terms>`
   If there is nothing new, skip this step.
8. **Log.** Run `date`. Append to `{{VAULT_DIR}}/wiki/log.md` with a surgical edit anchored on the last line, not a shell heredoc:
   `## [YYYY-MM-DD HH:MM] learned | <N> notes to personal inbox: <title>; <title>`
   Omit the titles when N is 0.
9. **Clean up and report.** Empty the drafts folder as in step 4. Then report: titles written, with full paths. Deduped links. Leak-check result (pass, or what was rewritten). Career evidence lines added.

## Who commits

This skill never runs git in the personal vault. If the personal vault has an auto-commit plugin or job, that commits and pushes. Otherwise the user commits. The work vault is committed by the normal work vault routine, not by this skill.

## Notes

- Make sure sessions rooted in the work vault may write to `{{PERSONAL_VAULT}}` without a prompt (for Claude Code: `permissions.additionalDirectories` in the vault's `.claude/settings.json`).
- Never edit or delete anything in the personal vault except to add inbox notes and the career evidence file.
