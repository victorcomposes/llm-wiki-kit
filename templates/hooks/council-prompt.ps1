# UserPromptSubmit hook - trigger the council on a design idea typed in chat.
# A prompt that reads as an idea or a fork (an idea verb AND a design noun, or the word
# "council") gets an instruction injected into the turn: convene /council before agreeing,
# refining or recommending. "no council" in the prompt skips it.
# This is a nudge the model sees every time, not a wall: no hook can spawn a subagent.
# ponytail: regex heuristic, fail-open. upgrade path if misses show up: a Stop hook that
# refuses to end the turn when this fired and no council-* agent ran and no "No fork:" answer.

$raw = [Console]::In.ReadToEnd()
try { $o = $raw | ConvertFrom-Json } catch { exit 0 }
$p = [string]$o.prompt
if (-not $p) { exit 0 }
if ($p -match '(?i)\bno council\b') { exit 0 }
if ($p -match '^\s*/') { exit 0 }   # slash commands are explicit already

$ideaVerb = '(?i)\b(what if|should (we|i)|shouldn''t (we|i)|thinking (of|about)|idea|instead of|option|options|approach|rather than|why not|could we|we could|vs\.?|versus|or should|alternatively|propos(e|al|ing)|what about|how about|better to)\b'
$designNoun = '(?i)\b(migration|table|column|schema|index|constraint|contract|dto|dtos|event|message|topic|queue|service|endpoint|api|aggregate|entity|value object|domain|handler|projection|snapshot|refactor|store|persist|cache|retry|outbox)\b'

$hit = ($p -match '(?i)\bcouncil\b') -or (($p -match $ideaVerb) -and ($p -match $designNoun))
if (-not $hit) { exit 0 }

$ctx = "Council trigger: this prompt reads as a design idea or a fork. Before you agree, refine, or recommend, " +
  "run the /council skill: write the brief with the idea as option A and the status quo or the nearest existing " +
  "pattern as option B, spawn council-simplicity, council-robustness and council-domain blind and in parallel, " +
  "then answer with the seats' verdicts and the split. If there is genuinely no second viable option, start your " +
  "answer with 'No fork:' and one line why, then answer normally. The user skips this by writing 'no council'."

@{ hookSpecificOutput = @{
    hookEventName     = 'UserPromptSubmit'
    additionalContext = $ctx
} } | ConvertTo-Json -Compress
exit 0
