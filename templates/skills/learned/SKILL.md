---
name: learned
version: 1.0.0
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
4. **Draft.** Read the personal vault's knowledge note template (look under its templates folder; ask once if unclear). For each candidate write one note to `%TEMP%\learned-drafts\` (`$TMPDIR/learned-drafts` on macOS or Linux). Clear that folder first.
   - File name in the style of the existing notes: `Concept - one-line meaning.md`. Do not use `: ? " / \ * < > |`.
   - Frontmatter exactly as the template has it.
   - Body sections: `## TL;DR` (2 or 3 bullets), `## WHAT THIS IS`, `## WHEN THIS MATTERS`, `## EXAMPLE` (neutral and invented).
   - Plain short sentences.
5. **Leak check before anything touches the personal vault.** Build the deny pattern and grep the drafts, both content and file names:
   ```bash
   D="$TEMP/learned-drafts"; P="$TEMP/learned-deny-pattern.txt"
   {
     ls "{{VAULT_DIR}}/wiki/services" | sed 's/[.]/\\./g'
     echo '{{TICKET_PREFIX}}-[0-9]+'; echo 'VLT-[0-9]+'
     grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "<this skill's folder>/deny.txt"
   } > "$P"
   grep -n -i -E -f "$P" "$D"/*.md ; ls "$D" | grep -n -i -E -f "$P"
   ```
   The pattern has three parts: every folder name under `wiki/services/`, the ticket id shapes, and every line of `deny.txt` (one case-insensitive regex per line, `#` comments, `\b` around short words). The user extends `deny.txt`.
   - No output from both greps (grep exit 1) is a pass.
   - Any hit: rewrite the draft in general terms, then run the whole check again. Delete a failing draft. Never copy a failing draft.
   - Also read each draft once. The deny list cannot know a name it has not seen. If you see a proprietary term, rewrite the draft and add the term to `deny.txt`.
6. **Copy.** Copy only passing drafts into the personal vault's inbox folder. Do not overwrite an existing file: if the name exists, stop and treat it as a dedupe hit. The user reviews the notes and moves them to the notes folder. Run the leak check once more over the copied files.
7. **Career evidence.** If the session or today's journal added lines to `wiki/brag.md` or `wiki/journal/evidence-log.md`, write a scrubbed version of each. Keep the category. Same leak check as step 5. Append as dated bullets to `Career evidence.md` in the personal vault (create it on first use, with the template's frontmatter and a `# Career evidence` heading):
   `- YYYY-MM-DD · <category> · **<title>** - <what was done and the result, in general terms>`
   If there is nothing new, skip this step.
8. **Log.** Run `date`. Append to `{{VAULT_DIR}}/wiki/log.md` with a surgical edit anchored on the last line, not a shell heredoc:
   `## [YYYY-MM-DD HH:MM] learned | <N> notes to personal inbox: <title>; <title>`
   Omit the titles when N is 0.
9. **Report.** Titles written, with full paths. Deduped links. Leak-check result (pass, or what was rewritten). Career evidence lines added.

## Who commits

This skill never runs git in the personal vault. If the personal vault has an auto-commit plugin or job, that commits and pushes. Otherwise the user commits. The work vault is committed by the normal work vault routine, not by this skill.

## Notes

- Make sure sessions rooted in the work vault may write to `{{PERSONAL_VAULT}}` without a prompt (for Claude Code: `permissions.additionalDirectories` in the vault's `.claude/settings.json`).
- Never edit or delete anything in the personal vault except to add inbox notes and the career evidence file.
