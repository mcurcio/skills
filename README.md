# skills

Matt Curcio's ([mcurcio](https://github.com/mcurcio)) shared engineering rules, skills and agents,
published as a [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
named `mcurcio-skills`. Matt's projects opt in to it, so every contributor's Claude Code session, and
every other agent or person who reads the files, works to the same rules, kept in one place.

"The owner" in these files is defined once, at the top of `plugins/rules/skills/global/SKILL.md`.

## The plugins

| Plugin | What it holds | Who enables it |
|---|---|---|
| `rules` | `global`: the engineering rules (design philosophy, the owner's language, delivery, always-on habits), injected into every session by a SessionStart hook. `owner-design`, `owner-delivery`, `owner-conversation`: the reasons and worked examples behind them. `pages`: how every page or report for the owner is presented. Requires `impeccable` | every project that opts in |
| `workflow` | `orchestrator`: the main session's policy (routing, workflows, owner gates, review), injected by a SessionStart hook. The agents `code-architect`, `system-architect`, `requirements`, `design-reviewer`, `implementer`, `verifier`, `deployer`, `general-purpose`. The skills `design-doc`, `implementation-workflow`, `antipattern-review`. Needs `rules` | every project, with `rules` |
| `releases` | `semantic-release`: releases cut automatically on merge, notes in `CHANGELOG.md`, the version in the git tag only | projects that release |
| `toolkit` | `grammar-soundness` (proving a grammar unambiguous, checking parsers against it) and `chrome-ui-testing` (test-driving a web UI in Chrome) | anyone who wants them |

Skills are named `<plugin>:<skill>` (`rules:owner-design`) and agents `<plugin>:<agent>`
(`workflow:implementer`). Claude also loads a skill on its own when its description matches the
task.

How the rules reach a session: a plugin cannot ship a `CLAUDE.md` as context, so each of `rules`
and `workflow` has a SessionStart hook (`hooks/inject.sh`) that prints its skill's text at the
start of every session and again after compaction. Hook output does not reach subagents, so this
repo's agents preload `rules:global` through their `skills:` frontmatter. CI keeps each injected
file under a size limit (`scripts/check.sh` says why).

## Opting a project in

Commit this as the project's `.claude/settings.json` (or merge it into the one there):

```json
{
  "extraKnownMarketplaces": {
    "mcurcio-skills": {
      "source": { "source": "github", "repo": "mcurcio/skills" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "rules@mcurcio-skills": true,
    "workflow@mcurcio-skills": true,
    "releases@mcurcio-skills": true
  }
}
```

Leave out `releases` if the project does not release. `workflow` gives contributors the maintainer's
main-session process and agents too (the maintainer's choice, 2026-11-01). `workflow` requires
`rules`, so keep both. A contributor gets the plugins once they trust the project folder in Claude Code; the first session may say "Plugins changed. Run
/reload-plugins". One person can turn a plugin off for themselves with
`"rules@mcurcio-skills": false` in `.claude/settings.local.json`.

Add a pointer to the project's `AGENTS.md` for other agents and for people:

> This project follows its maintainer's shared engineering rules: https://github.com/mcurcio/skills
> (`plugins/rules/skills/global/SKILL.md`, with the reasons in the `owner-*` skills beside it). Claude
> Code loads them through `.claude/settings.json`; other agents and people read them there. A rule here
> that quotes the maintainer overrides them for this project.

To use the plugins in every project on your machine instead:

```
/plugin marketplace add mcurcio/skills
/plugin install rules@mcurcio-skills
/plugin install workflow@mcurcio-skills
```

A marketplace added this way does not update on its own: turn on auto-update for `mcurcio-skills`
in `/plugin` > Marketplaces, or put the `extraKnownMarketplaces` entry above (with `"autoUpdate":
true`) in your user settings, `~/.claude/settings.json`.

### Cloud sessions

A Claude Code cloud session (claude.ai/code) ignores a project's `.claude/settings.json` plugins,
because it never shows the trust dialog, and plugins load only if they are installed before Claude
Code starts. Give the cloud environment this setup script, which runs before Claude Code:

```sh
claude plugin marketplace add mcurcio/skills || true
sh "$HOME/.claude/plugins/marketplaces/mcurcio-skills/scripts/cloud-setup.sh" || true
```

`scripts/cloud-setup.sh` installs every GitHub marketplace and plugin that any checked-out
project's `.claude/settings.json` turns on, so one environment serves every project that opts in.
It trusts those projects' settings as the trust dialog would have, so use it only in an
environment whose repositories you trust.

### Following releases

Every plugin here follows `main`: no plugin file carries a version, so each merge reaches every
auto-updating user, whether or not it cut a release. The `v*` tags record releases. A project that
wants only released states pins the marketplace with `"ref": "v1.2.3"` in its `source` and bumps
it by hand.

## Recommended plugins by other authors

These skills are good and are not republished here. Install them from their authors:

| Plugin | Author | Install |
|---|---|---|
| [impeccable](https://github.com/pbakaus/impeccable) (frontend design, critique and polish) | Paul Bakaus | `/plugin marketplace add pbakaus/impeccable`, then `/plugin install impeccable@impeccable` |
| [security-audit](https://github.com/cloudflare/security-audit-skill) (security review and audits) | Cloudflare | `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit` |
| [domain-modeling](https://github.com/mattpocock/skills) (a project glossary and decision records) | Matt Pocock | `/plugin marketplace add mattpocock/skills`, then `ln -s ~/.claude/plugins/marketplaces/mattpocock/skills/engineering/domain-modeling ~/.claude/skills/domain-modeling` |

`domain-modeling` is linked on its own because a plugin's skills cannot be enabled one at a time,
and this plugin's others include a spec-to-implementation chain that conflicts with `workflow`.

Superpowers and ponytail are not recommended alongside these plugins, because they conflict with
the rules here. Superpowers reviews after each task, where `workflow:orchestrator` has one review
at the end. Ponytail flags an interface with one implementation as unnecessary, where
`rules:owner-design` says the number of implementations is not the test.

## Contributing

- Change a rule in exactly one place. A rule lives in `rules:global` or `workflow:orchestrator`,
  or, for one role, in that agent's body; the reasons for it live in an `owner-*` skill; a rule
  for one project stays in that project.
- Name a skill or agent in another plugin by its scoped name (`rules:owner-delivery`), and a
  file in the same plugin by `${CLAUDE_PLUGIN_ROOT}/...`, never by a path on your machine.
- Nothing private: no local paths, email addresses, host names, secrets or details of private
  projects. Cite a private project as "a private project".
- Run `scripts/check.sh` after `npm ci` (Node 24, see `.nvmrc`; set `CLAUDE` to your `claude`
  binary, or to `node_modules/.bin/claude`). CI runs the same on every pull request.
- Plugin evals live in `evals/` and need a logged-in `claude` (CI does not run them). Run them
  from the repo root, with results under `.work/`, which the privacy check skips:
  `claude plugin eval . --tag trigger --ablation none --output-dir .work/evals/trigger`. Run the
  `hook` tag first and without `--ablation none`: its no-plugin arm is the control. The `framing` tag grades questions and requirements with a judge
  model, so it costs more than the free `hook` and `trigger` graders. An eval run
  installs nothing, so a plugin with an unmet `dependencies` entry is disabled while the run
  still scores, and only that case's failure shows it. Each case lists the plugins it needs in
  `plugins`; a dependency from another marketplace cannot be met in an eval.
- Commits and pull request titles follow [Conventional Commits](https://www.conventionalcommits.org):
  `fix` cuts a patch release, `feat` a minor one, `!` or `BREAKING CHANGE:` a major one. Merging
  to `main` is the release: semantic-release appends the notes to `CHANGELOG.md`, tags `v<version>`
  and makes the GitHub Release. Never tag or write a version by hand.
