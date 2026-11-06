#!/usr/bin/env bash
# Runs evals/ with `claude plugin eval`; arguments pass through. An eval run installs nothing, so
# a plugin whose manifest lists `dependencies` is disabled at startup, and the run still scores
# (the only trace is plugin_errors in its transcript). workflow needs rules, which needs a plugin
# from another marketplace. So this tests a copy in .work/ whose manifests drop that one field;
# the skills, agents and hooks are byte-identical. A case that needs a plugin names it in `plugins`.
set -eu
cd "$(dirname "$0")/.."
target=.work/eval-target
rm -rf "$target"
mkdir -p "$target/plugins"
cp -R plugins/workflow plugins/rules "$target/plugins/"
cp -R evals "$target/evals"
for manifest in "$target"/plugins/*/.claude-plugin/plugin.json; do
  node -e '
    const fs = require("fs"), f = process.argv[1], m = JSON.parse(fs.readFileSync(f, "utf8"));
    delete m.dependencies;
    fs.writeFileSync(f, JSON.stringify(m, null, 2) + "\n");' "$manifest"
done
exec "${CLAUDE:-claude}" plugin eval "$target" "$@"
