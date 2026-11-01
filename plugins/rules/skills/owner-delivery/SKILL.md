---
name: owner-delivery
description: Why the owner wants work tested, landed and shipped the way his rules say. Reasons and incidents behind the delivery rules in the `rules:global` rules and the agent bodies - CI as the gate, one review at the end, fan-out on disjoint files, evidence over status, tests that prove behaviour, fast tests, unpiped exit codes, undoing edits safely, honest "pre-existing" and NOT RUN claims, landing by PR, watching PRs, releases from the automated flow, pinned runtimes, run estimates, deploy discipline. Use when implementing, verifying, deploying, triaging a red, or deciding what proves a change works.
---

# How the owner wants work shipped

The rules are in `rules:global` §Delivery and §Always, your agent body, and for the main
session the `workflow:orchestrator` policy §Verification and PRs. This file gives the reasons and the
craft; where it seems to differ from a rule, the rule wins.

## Evidence, not status

- **Capability over status.** In a private project a replicated database reported every replica
  ready for an unknown time while its failover path was dead; only a switchover drill and a real
  restore proved anything. Bind assertions to the tool's own vocabulary (Pulumi ops `same` or
  `update`), not to a log that went quiet. In another, the web app broke for every signed-in
  user while every UI test passed, because the browser suite stubbed out the check that failed;
  controller specs passed while the production binary returned 400 to every POST, because the
  specs built a different HTTP pipeline. In a third, `swift test` ran zero assertions and still
  exited 0.
- **Mutation probes** prove a test can fail. A cross-package probe in a private monorepo stayed
  green because the test ran the stale built `dist/` while source maps pointed at `src/`.
- **Pipes.** An implementer reported verify green; the e2e stage had exited 1 with failures, and
  the green was `tee`'s exit code.
- **Undoing edits.** A verifier restored a probed file with `git checkout` and wiped the
  implementer's uncommitted fix; in photo-wall the same move discarded a whole batch, recovered
  only by replaying edits from transcripts.
- **"Pre-existing" and NOT RUN.** An implementer in a private project built a tracker item it
  was never assigned, left 13 failures, and called them pre-existing with a grep that proved
  nothing. In photo-wall a red browser test was re-run as an unrelated flake because the PR had
  not touched that page; the PR had caused it. In another private project a partial check
  followed by a push landed red CI on main. A skipped check stated plainly costs nothing; an
  invented green costs a release.

## Tests he values

- photo-wall, after a PR with 6.1k test lines for 3.8k product lines: "I prefer integration tests
  that exercise functional requirements rather than unit tests which exercise internal code".
  A private infrastructure repo keeps unit tests for library logic and functional health checks
  for workloads. The shared rule is behaviour through the real artifact; the unit-to-integration
  balance is the repo's.
- "All tests should be fast by design": a slow tier is a concession, not a default. He rejected a
  10-minute outage step in a CI leg.

## Landing and shipping

- **CI is the gate.** Local full verifies serialized every milestone's check, fix and re-verify
  chain ("there is no reason to do that locally"). In photo-wall one workstream took 6 hours
  ("an insane amount of time"), a third of it verifiers re-running locally, at 27 minutes a pass,
  tiers CI ran in parallel in about 12.
- **By PR, merged by him.** "Always PR; never a direct deploy" (a private infrastructure repo):
  the PR keeps a review and audit gate and avoids ad-hoc interactive deploys. In one repo a bot
  account opens PRs and the owner's own account is not signed in, so it cannot be used by mistake.
- **Watched PRs.** Asked whether to watch a PR, he answered "Always": red CI and unread comments
  had sat unnoticed between batches.
- **Releases.** He refused to hand-tag a release candidate ("The GHA workflow is supposed to
  handle versioning"). A squash-merge under a non-conventional title released nothing, because
  the commit type drives the version bump. In ear he rejected release-please's standing release
  PR (2026-11-01: "I don't like release-please. I prefer semantic release and auto releases
  after PRs are merged"): merging the work is the release, with no second PR to merge.
  How: the `releases:semantic-release` skill.
- **The implementer lands its own slice.** A separate commit agent costs about 60k tokens of
  context for one `git commit`; one run spent 19% of its tokens on nine of them.
- **Green work is never reverted over paperwork.** A 14-hour run landed 2 of 64 beads, partly
  because verified code was reverted over documentation findings and the loop paid again.
- **Pinned runtime.** Wrong-Node reds look like code: a private project's
  `crypto$2.getRandomValues is not a function` and 29 photo-wall console failures both came from
  a shell defaulting to Node 16.

## Time and cost

- **Estimates and briefs.** A design workflow in a private project ran 24 agents with about 180k
  characters of discovery pasted into every prompt; after 90 minutes it had not reached its gate
  and he stopped it: "this is a failed process" (he had expected the whole feature built in that
  time). A photo-wall estimate built from the brief's planning figure (85 minutes a bead) said
  6 hours ("6 hours?!? that's crazy"); measured commit times said about 33 minutes a bead.
- **A problem, not a solution.** A workflow handed a pre-decided answer freezes a plan made
  before anything was learned, and every discovery becomes a round trip through the main loop.
- **One review, at the end.** The 6-hour photo-wall workstream (CI is the gate, above) spent
  2 h 15 min in per-lane verify, fix, re-verify and re-review loops; each re-review found a new
  edge (a port, a licence, IPv6) and restarted the loop. His words in photo-wall: "Don't waste
  time verifying each bead in isolation" (2026-09-26); "each adversary and verification must be
  'worth it'. Do larger batches of implementation before paying the overhead of review and
  verification" (2026-10-01). A private project had asked for a verifier and a security review
  at each milestone ("I certainly would prefer to catch issues sooner rather than later",
  2026-10-04); on 2026-10-09 he kept the newer answer ("keep the newer rules"). The early signal
  that remains is CI on every push.
- **Fan out.** Serial implementers at 20-30 minutes each, every one re-reading a 1,400-line
  design, made a photo-wall delivery take hours: "There should be an orchestration and fanout
  process where one agent reviews the design and spawns many cheaper/faster subagents to quickly
  build" (2026-09-26); he chose the same checkout, with disjoint files and no merge step. Later,
  slices run one after another inside each lane took 2 h 15 min while the lanes themselves ran in
  parallel. In a private project, parallel worktrees inside one package were offered and not
  used (setup cost, merge conflicts, machine load); fan-out on disjoint files in one checkout has
  no merge to pay.

## Deploying

A preview is not an apply, and the deployer reports rather than decides, because a wrong
Pulumi op deletes live resources: in a private infrastructure repo a mistimed stack merge can
delete what a state move was meant to keep. The heads-up before an interactive-auth command
exists so the owner is ready to answer its prompt (a password-manager or biometric unlock,
sudo), which a background agent would leave hanging.
