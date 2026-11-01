#!/bin/sh
# SessionStart hook: print one of this plugin's skills (its SKILL.md without the frontmatter)
# so its rules are in context from the session's start, and again after compaction. The same
# file is the skill that this repo's agents preload, since SessionStart output never reaches
# subagents. Hook output is capped at 10,000 characters; scripts/check.sh fails a file over 9,500.
f="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/skills/$1/SKILL.md"
[ -f "$f" ] || exit 0
awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$f"
