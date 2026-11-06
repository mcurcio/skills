---
name: semantic-release
description: Load before setting up, changing, migrating or debugging how a repo cuts releases (versions, tags, GitHub Releases, versioned images or packages): "set up releases", "why didn't it release", "replace release-please", "publish on merge", "bump the version". Covers the owner's rule (semantic-release, automatic on merge, never release-please), the workflow shape (release job gated on the checks, version from the tag never committed, versioned artifacts built in the same run), the config, the first release, migrating off release-please, and the traps.
---

# Releases: semantic-release on merge

The rule (semantic-release on merge, never release-please, and when Lerna is allowed) is in
`rules:global` §Delivery, and the owner's words for it
(2026-11-01) are in `rules:owner-delivery`; this page is how to build and run it.

Precedents: **knobly** (`.github/workflows/ci.yml` job `release`, `.releaserc.json`, root
`package.json`, `.github/release-build.sh`) is the reference single-version setup.

## 1. The shape

- Merging a PR to the default branch is the release. No release PR, no hand tag, no hand-edited
  version, no pre-merge release path.
- Conventional Commits decide the bump: `fix` patch, `feat` minor, `!` or `BREAKING CHANGE:`
  major, every other type nothing. Every commit in the merged range counts, so a merge commit
  keeps its PR's commits; a squash-merge counts only its title.
- The release job lives in the same workflow as the checks and `needs:` all of them, runs only
  on a push to the default branch, and is never cancelled
  (`concurrency: { group: release, cancel-in-progress: false }`).
- Every release appends its notes to `CHANGELOG.md` at the repo root (owner, 2026-11-01:
  "Make sure that releases also append to a CHANGELOG.md in the root"):
  `@semantic-release/changelog` writes it, and `@semantic-release/git` commits only that file
  as `chore(release): <version> [skip ci]` and pushes it to the default branch. The tag is put
  on that commit. The notes also go on the GitHub Release.
- The version lives in the git tag `v<version>`, the GitHub Release and CHANGELOG.md, never in
  a source or manifest file. A build that needs it is handed it (an argument, a build arg) and
  stamps it for that build only (knobly's `release-build.sh` restores the files on exit).
- An artifact that carries the version (container image, package) is built and published by a
  job in that same workflow, after the release job, reading the version from the release job's
  output. A release made with `GITHUB_TOKEN` starts no other workflow, so a separate
  "on release" workflow never runs. It checks out the release tag
  (`ref: ${{ needs.release.outputs.tag || github.sha }}`): the tag sits on the CHANGELOG
  commit, not on `github.sha`.
- Unversioned channel tags (`master`/`stable`, `sha-<commit>`) publish on every default-branch
  push, released or not, so a CI or Docker fix still ships.

## 2. Config

Root `package.json` (private, release tooling only) pins exact versions, with a lockfile:
`semantic-release`, `@semantic-release/commit-analyzer`, `@semantic-release/release-notes-generator`,
`@semantic-release/changelog`, `@semantic-release/git`, `@semantic-release/github`, and
`@semantic-release/exec` when a step needs the version. Run it
under the repo's pinned Node (`.nvmrc`). `.releaserc.json`:

```json
{
  "branches": ["master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", { "changelogFile": "CHANGELOG.md" }],
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md"],
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    ["@semantic-release/exec", {
      "verifyReleaseCmd": "if [ -n \"$GITHUB_OUTPUT\" ]; then echo \"version=${nextRelease.version}\" >> \"$GITHUB_OUTPUT\"; echo \"tag=${nextRelease.gitTag}\" >> \"$GITHUB_OUTPUT\"; fi"
    }],
    ["@semantic-release/github", {
      "successCommentCondition": false, "failCommentCondition": false, "releasedLabels": false
    }]
  ]
}
```

- `branches` names the real default branch (`main` or `master`).
- The git plugin's push needs the default branch to let `GITHUB_TOKEN` push. If it is
  protected, ask the owner for a bypass token stored as a repository secret. A push made with
  `GITHUB_TOKEN` starts no workflow, and `[skip ci]` guards the token case.
- Never let the git plugin commit anything but CHANGELOG.md (no version files, no `package.json`).
- Listing `plugins` replaces the defaults, which include `@semantic-release/npm`; list it only
  when the repo publishes to npm.
- Comments, labels and failure issues are off, so the job needs only `contents: write` (needed
  in dry-run too: semantic-release checks push access first). Check out with `fetch-depth: 0`
  and `persist-credentials: false`; pass `GITHUB_TOKEN: ${{ github.token }}` in the step's env.
- The step that runs semantic-release has an `id`; downstream jobs read
  `steps.<id>.outputs.version` through the job's `outputs`. Empty means no release this push.
- Release assets: `@semantic-release/github` `assets`, built by an exec `prepareCmd` (knobly).
- Run the release build (the `prepareCmd` script) in CI on every PR too, with a made-up
  version, so a broken release build fails on the PR, not on the default branch (knobly's
  `release-build` job).
- A dry-run gate (knobly's `RELEASE_ENABLED` variable) only when the owner asks for one.

## 3. First release and 0.x

- No `v*` tag yet: the first release is `1.0.0`, whatever the history says. semantic-release
  has no 0.x mode; a breaking change on 1.x makes 2.0.0. If the owner wants 0.x, ask, then seed
  a tag (`v0.1.0` on an old commit) by his hand or a one-off run he approves.
- The first release reads the whole history. A `git subtree add` without `--squash` merges the
  upstream project's whole history into the repo, so those commits are ancestors too. Their
  git-style `Revert "..."` messages parse as reverts and land in the notes and, for good, in
  CHANGELOG.md (ear: about 13 from Catch and nlohmann json). Later releases read only the
  commits since the last tag. Fix: a baseline tag `v0.0.0` on the last `git subtree add`
  (find it with `git log --grep=git-subtree-dir`), pushed once with the owner's yes. The
  first release then reads only the repo's own commits, and `v0.0.0` plus a `feat!` gives
  `1.0.0`. Never rewrite the default branch's history to squash old imports: every commit id
  changes, which breaks every clone, worktree, open PR and `sha-` image tag.
- Vendored dependencies show only as one line each (owner, 2026-11-01: "other than a
  'upgraded dependency X to release a.b.c' line"). Every update is
  `git subtree pull --prefix <dir> <repo> <ref> --squash -m "build(deps): upgrade <X> to <a.b.c>"`,
  and so is a bump of a fetched or pinned dependency. Configure both plugins with
  `preset: "conventionalcommits"`, a "Dependencies" section for `build(deps)`, and a
  `releaseRules` entry `{type: "build", scope: "deps", release: "patch"}` (ear's
  `.releaserc.json` is the worked example). Pin `conventional-changelog-conventionalcommits`
  to the major that release-notes-generator's own writer supports (9.x for generator 14.1.1;
  10.x fails with "requires conventional-changelog-writer@9"). The preset's `types` match on
  `scope`, so `{type: "build", scope: "deps"}` shows only dependency bumps.
- If the release job fails after the git plugin pushed the CHANGELOG commit and tag, no rerun
  recovers it: make the GitHub Release by hand from that version's CHANGELOG section
  (`gh release create v<version> --verify-tag`). That version's image does not get published.
- Tags by another tool count only if they match `tagFormat` (default `v${version}`).

## 4. Migrating off release-please

1. Delete `release-please-config.json`, `.release-please-manifest.json`, the
   `googleapis/release-please-action` job, and every `x-release-please-*` marker; drop the
   hard-coded version the marker guarded (e.g. CMake `project(... VERSION x.y.z)`) unless the
   build reads it, and then stamp it from the tag instead.
2. Close the open `chore(<branch>): release x.y.z` PR with a comment naming the replacing PR,
   and delete its `release-please--branches--*` branch, once the replacing PR merges (until then
   release-please keeps refreshing it).
3. The Actions setting "Allow GitHub Actions to create and approve pull requests" is no longer
   needed; tell the owner he may turn it off.
4. Fix every doc that says how releases happen (AGENTS.md, CONTRIBUTING, design docs, skills).

## 5. Traps

- A squash-merge whose PR title is not a Conventional Commit releases nothing.
- `chore`, `docs`, `ci`, `test`, `refactor` release nothing: a change that should ship as a new
  version needs `fix` or `feat`.
- A rerun of a failed publish job after the release job succeeded must still find the version:
  read it from the release job's output (kept on rerun of failed jobs) or from
  `git tag --points-at HEAD 'v*'`, never from "release created" alone.
- semantic-release refuses to run on a shallow clone or a detached commit not on `branches`.
- Prove the setup with `npx semantic-release --dry-run --no-ci` locally (needs a token with
  read access) before the first merge; it prints the next version and notes, and changes
  nothing.
