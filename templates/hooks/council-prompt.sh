#!/usr/bin/env bash
# UserPromptSubmit hook - trigger the council on a design idea typed in chat (POSIX variant, requires jq).
# Injects the instruction to convene /council when the prompt has an idea verb AND a design noun,
# or the word "council". "no council" skips. council-prompt.ps1 is the reference implementation.
# ponytail: regex heuristic, fail-open. no hook can spawn a subagent; this is a nudge the model sees.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
p=$(printf '%s' "$input" | jq -r '.prompt // empty')
[ -n "$p" ] || exit 0
printf '%s' "$p" | grep -qiE '\bno council\b' && exit 0
printf '%s' "$p" | grep -qE '^[[:space:]]*/' && exit 0

verb='\b(what if|should (we|i)|shouldn.t (we|i)|thinking (of|about)|idea|instead of|options?|approach|rather than|why not|could we|we could|vs\.?|versus|or should|alternatively|propos(e|al|ing)|what about|how about|better to)\b'
noun='\b(migration|table|column|schema|index|constraint|contract|dtos?|event|message|topic|queue|service|endpoint|api|aggregate|entity|value object|domain|handler|projection|snapshot|refactor|store|persist|cache|retry|outbox)\b'

if printf '%s' "$p" | grep -qiE '\bcouncil\b'; then hit=1
elif printf '%s' "$p" | grep -qiE "$verb" && printf '%s' "$p" | grep -qiE "$noun"; then hit=1
else exit 0; fi

ctx="Council trigger: this prompt reads as a design idea or a fork. Before you agree, refine, or recommend, run the /council skill: write the brief with the idea as option A and the status quo or the nearest existing pattern as option B, spawn council-simplicity, council-robustness and council-domain blind and in parallel, then answer with the seats' verdicts and the split. If there is genuinely no second viable option, start your answer with 'No fork:' and one line why, then answer normally. The user skips this by writing 'no council'."
jq -cn --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'
exit 0
