#!/bin/sh
# Installs, for a Claude Code cloud environment, the plugins each checked-out repository turns on.
#
# A cloud session never shows the workspace trust dialog, so it ignores extraKnownMarketplaces
# and enabledPlugins in a repository's .claude/settings.json, and plugins load only if they are
# installed before Claude Code starts. So the environment's setup script, which runs before
# Claude Code, installs them. Make the setup script these two lines (README, "Cloud sessions"):
#
#   claude plugin marketplace add mcurcio/skills || true
#   sh "$HOME/.claude/plugins/marketplaces/mcurcio-skills/scripts/cloud-setup.sh" || true
#
# The first line fetches this repository, and with it this script. The setup script starts in
# the directory that holds the checkouts; pass another directory as the first argument. Every
# GitHub marketplace and plugin any repository there turns on is installed at user scope, so a
# repository's settings are trusted as if its folder had been. No repository file is changed.
# A failure is printed and skipped: a failing setup script would stop the session starting.
set -u

for settings in "${1:-.}"/*/.claude/settings.json; do
  [ -f "$settings" ] || continue
  jq -r '.extraKnownMarketplaces // {} | to_entries[]
    | select(.value.source.source == "github") | .value.source.repo' "$settings" |
    while read -r repo; do claude plugin marketplace add "$repo" || true; done
  jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$settings" |
    while read -r plugin; do claude plugin install "$plugin" || true; done
done
exit 0
