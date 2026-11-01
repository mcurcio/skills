#!/usr/bin/env bash
# The repo's checks, run by CI on every pull request and runnable locally from the repo root:
#   1. Claude Code's validator on the marketplace and each plugin. Its only tolerated warning is
#      the missing "version": the version lives in the git tag, never in a file (README).
#   2. Every skill and agent opens with frontmatter giving a name and a description (the
#      validator does not check this).
#   3. Each file a SessionStart hook injects stays under 9,500 characters: hook output over
#      10,000 arrives cut to a short preview that Claude is not told to read past.
#   4. The plugins' copies of hooks/inject.sh are identical (one script, copied because a
#      plugin cannot read another plugin's files).
#   5. Nothing private: no local home paths, mounted volumes, email addresses or secret refs.
set -u
cd "$(dirname "$0")/.."
claude="${CLAUDE:-claude}"
fail=0
err() { echo "FAIL: $*"; fail=1; }

for target in . plugins/*/; do
  out="$("$claude" plugin validate --json "$target")"
  rc=$?
  [ "$rc" -eq 0 ] || err "claude plugin validate $target exited $rc"
  printf '%s' "$out" | node -e '
    let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
      const r = JSON.parse(s), bad = [];
      const walk = v => { if (Array.isArray(v)) v.forEach(walk); else if (v && typeof v === "object") {
        for (const w of v.warnings || []) if (!/(^|[ .])version$/.test(w.path || "")) bad.push(`warning ${w.path}: ${w.message}`);
        for (const e of v.errors || []) bad.push(`error ${e.path}: ${e.message}`);
        Object.values(v).forEach(walk); } };
      walk(r); if (bad.length) { console.log(bad.join("\n")); process.exit(1); } });' \
    || err "validator findings for $target"
done

while IFS= read -r f; do
  head -1 "$f" | grep -qx -- '---' || { err "$f: no frontmatter"; continue; }
  fm="$(awk 'NR > 1 && $0 == "---" { exit } NR > 1' "$f")"
  printf '%s\n' "$fm" | grep -q '^name: [a-z0-9-]\{1,\}$' || err "$f: frontmatter has no valid name"
  printf '%s\n' "$fm" | grep -q '^description: .' || err "$f: frontmatter has no description"
done < <(find plugins -path '*/skills/*/SKILL.md' -o -path '*/agents/*.md')

for hooks in plugins/*/hooks/hooks.json; do
  plugin="$(dirname "$(dirname "$hooks")")"
  for skill in $(grep -o 'inject\.sh\\" [a-z0-9-]*' "$hooks" | awk '{ print $2 }'); do
    n="$(CLAUDE_PLUGIN_ROOT="$plugin" sh "$plugin/hooks/inject.sh" "$skill" | wc -m | tr -d ' ')"
    [ "$n" -gt 0 ] || err "$plugin injects $skill, which printed nothing"
    [ "$n" -lt 9500 ] || err "$plugin/skills/$skill/SKILL.md injects $n characters (limit 9,500)"
  done
done

first=""
for s in plugins/*/hooks/inject.sh; do
  [ -z "$first" ] && first="$s" && continue
  cmp -s "$first" "$s" || err "$s differs from $first"
done

if grep -rnIE '/Users/|/Volumes/|/home/[a-z]|op://|[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' \
     --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.work \
     --exclude=package-lock.json --exclude=CHANGELOG.md --exclude=check.sh . \
   | grep -vE 'noreply@anthropic\.com|@semantic-release/|@anthropic-ai/'; then
  err "private-looking text above"
fi

[ "$fail" -eq 0 ] && echo "RESULT=PASS"
exit "$fail"
