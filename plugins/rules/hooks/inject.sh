#!/bin/sh
# SessionStart hook: print one of this plugin's skills (its SKILL.md without the frontmatter)
# so its rules are in context from the session's start, and again after compaction. The same
# file is the skill that this repo's agents preload, since SessionStart output never reaches
# subagents. scripts/check.sh limits the file's size and says why.
f="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/skills/$1/SKILL.md"
[ -f "$f" ] || { echo "inject.sh: no skill '$1' at $f; its rules are not loaded" >&2; exit 1; }
awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$f"
