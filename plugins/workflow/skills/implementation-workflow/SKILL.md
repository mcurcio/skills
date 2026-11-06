---
name: implementation-workflow
description: BINDING model for any implementation workflow — turning an approved design into landed code, attended or unattended. Load BEFORE cutting beads, BEFORE writing or launching an implementation or refactor workflow script, and whenever a bead cannot land green on its own. Covers slicing (few large vertically green compile units, tracer first), bead-cutting rules, the per-slice land step, fan-out of slices with disjoint files, the one verify/review/fix at the end with CI as the full gate, budget gates, environment preflight, model choice, wip/ preservation, the cold-start handoff, workflow-script gotchas, and refactor work (candidates found toward a target idiom, in tiers of rising cost). Pairs with workflow-authoring (which covers the script API, not the development model).
---

# implementation-workflow

An approved design frame is turned into code by **vertical slices**, each independently
green, cut on **compile-unit** boundaries, ordered **tracer-first** and
**package-depth-first**. The whole-feature code-architecture freeze is gone; interfaces are
frozen **per slice**, one page at a time. Slices are **few and large** and fan out where their
files are disjoint; verification and review run **once, at the end, over everything**, and **CI
is the full gate**.

Why this exists: `reference/2026-09-02-unattended-run-retrospective.md` — 14 hours, ~5.5M
tokens cited (~7M estimated), 2 of 64 beads landed. The beads were cut along interface artifacts across
many packages, so no vocabulary bead could ever be green alone; every bead paid a
30–60 minute fixed cost for 5 minutes of change; docs sat inside the green gate;
two verified beads were reverted over paperwork. The design gate, the adversarial
design review and the tracer-first ordering worked and are kept.

The owner's answers this skill applies live in the always-loaded files and bind over anything
older here: few large slices, fan-out on disjoint files and one review at the end
(`workflow:orchestrator` §Workflows), CI as the full gate (`rules:global` §Delivery), and models
(`rules:global` §Always). Also from the batch-review answer: no pre-code review of the
slice cut, and no preflight that re-runs a baseline a setup step already ran.

## 1. What stays from the design phase (unchanged, binding)

- ONE design document per owner gate, written per the `workflow:design-doc` skill, reviewed
  by the owner on a PR. Merge is acceptance.
- Adversarial, multi-lens review of the **design** (security, correctness,
  regression, completeness, plus a domain expert) before any code. Reviewers attack the
  design's premises with the problem evidence and may read the code to test claims; they are
  not handed the bead list. This is where P0s are cheap.
- The **tracer bullet** defined in the design: the thinnest end-to-end path through
  the riskiest seam (usually authz or data loss). Its named mutation probes are written on
  the tracer slice's frozen page (§2), not in the design briefing, which `workflow:design-doc` keeps
  free of probes.

## 2. What replaces the code-architecture phase

There is no whole-feature interface freeze and no 45-node DAG. Instead:

1. **Slice the frame.** From the approved design, list vertical slices. A slice is
   the smallest change that is green end-to-end and delivers one observable behaviour (a
   route that answers, a decision that refuses, a helper that fills). The first slice is the
   tracer. Prefer few large slices: target 3–5 code slices plus 1 docs slice per milestone,
   each several hours of change.
2. **Freeze per slice, one page.** Before a slice is implemented, write the exact
   signatures it introduces or changes (types, error codes, migration columns, route
   declaration rows) — nothing beyond that slice. Put the page in the slice's bead
   text. Shared primitives that two *future* slices will both need are frozen when the
   first of those slices is cut, not up front. Each milestone starts with a code architect
   writing its slices' pages and committing the interfaces as compiling code (no bodies).
3. **Review by risk, once at the end.** No adversarial review of the cut or the pages before
   code; the code architect self-checks them. A change touching authz, secrets, money,
   migrations, deletion or a public API gets a security lens in the end review (§4).

## 3. Bead-cutting rules (a bead is one slice, or one compile unit of a slice)

A **compile unit** is the set of files that must change together to keep the
type-checker and the totality tests green: an api enum, its consumers and their
tests are one unit, not three. A **milestone** is a landed group of slices with
observable behaviour (a route that answers end to end, the tracer, a UI surface).

1. **Green-alone.** Every bead must pass its changed packages' tests, typecheck and lint (§4)
   by itself on top of the previous landed bead, and CI on push. If it cannot, merge it with
   what it needs. A bead that "will be green once the next bead lands" is a cutting error, not
   a sequencing note.
2. **Co-change.** A bead that grows an enum, a union, a discriminated kind, a role
   set or a wire vocabulary carries **every consumer and every test that encodes the
   old vocabulary**. Tripwire refactors (exhaustive switches, `assertNever`, totality
   tests) land in the same bead as the first growth they guard, never before an
   unrelated bead grows the vocabulary. **If the consumers span more than two
   packages, the vocabulary is not yet a slice:** introduce the new member
   *additively* first (no `assertNever` on it; consumers keep a default arm that
   refuses, never one that silently widens), migrate consumers package by package,
   and land the totality tripwire as the last bead once every consumer is migrated.
   Totality is earned, not cut breadth-first.
3. **Size to the overhead.** One bead is at least one hour of human-equivalent change, and
   preferably several, and no larger than what clears the per-bead wall-clock ceiling (§5) in
   one agent pass. Below an hour, merge; above the ceiling, split on a compile-unit seam,
   never on a file-type seam.
4. **Depth before breadth.** A bead lives in one package, two at most (the tracer is
   the exception). Order packages by dependency: finish the package others import
   before its importers. A layer that touches six packages is a smell.
5. **Self-contained text.** The bead carries its own frozen page, files, acceptance
   criteria and mutation probe. An implementer reads the bead and the design's
   relevant section, never the whole feature's documents.
6. **Docs are their own beads.** Spec rows, README, CLAUDE.md and deployment notes
   are cut as a docs bead per milestone. A code bead is never failed, and never
   reverted, on a documentation finding.
7. **No coherence bead per layer.** One coherence review, in the end review (§4), never per
   package layer or milestone. A milestone is not closed, and its PR is not merged, until its docs
   bead has landed: an open docs bead blocks the milestone the way an open erratum
   blocks coherence.
8. **Residual findings become beads.** P1/P2 findings on a landed bead that are not
   correctness defects become `residual:` beads, not reverts.

## 4. The land loop (attended or unattended)

**Fan-out** (the rule: `workflow:orchestrator` §Workflows). Lanes in disjoint packages each
run in their own worktree, with their own preflight (§6), and land on the one PR branch. Inside a
lane, the tracer slice lands first; after it, slices whose file sets are disjoint run
concurrently in the lane's checkout, and a slice that depends on another waits for it. Each
slice's text lists the files it owns (§3.5) and says that siblings share the checkout; its
agent keeps to them (the fan-out line in `workflow:implementer`; a default-type agent
gets it in its brief), and seams between slices are the end fix's. Give a worktree agent
`isolation: "worktree"`, never a path into another worktree (a subagent Write across worktrees
was refused, 2026-10-04).

Siblings in one checkout share its git index and its derived state, so git, not memory, keeps
them apart:

- **Disjoint counts what checks write.** A slice's owned set includes the outputs its checks
  write: the package `dist`, generated code, build caches. Two slices that write the same output
  are not disjoint: run them in sequence, or have both check without writing it (no-emit
  typecheck, tests from source) and rebuild it once after both land. A dependency change
  (manifest, lockfile) never fans out.
- **The land command names the paths.** The workflow script writes each slice's land command
  into its brief from the owned list: `git add -A -- <owned> && git commit -m '<msg>' -- <owned>`,
  then push. Given paths, git commits HEAD plus those paths only, so nothing a sibling staged or
  left untracked rides along; `git commit` with no paths takes every staged path, and `git add -A`
  with none takes every sibling's file (both probed, 2026-10-09). A commit that meets a sibling's
  `index.lock` waits and retries.
- **Nothing is left over.** When every slice has landed, `git status --porcelain` in the checkout
  is empty; anything left is a write outside an owned list, and the run stops on it.

**Per slice — one agent** (an `implementer` whose brief says commit and push, or a
default-type agent):

| Runs | Rule |
|---|---|
| changed packages' tests (in parallel, `-n 4` or equivalent), typecheck, lint | reads the bead text only; rebuilds the package `dist` it changed; appends errata on a spec contradiction and stops; implements only its own bead even if the tracker shows others ready |
| commit, ledger row, push | Conventional Commit per bead; commits only its own files, with its paths named in the commit (Fan-out, above). Hook bypass: `--no-verify` only when the brief allows it (the repo hook re-runs what the agent already ran); NEVER `git -c core.hooksPath`, git config changes or edits under the hooks directory; a commit blocked for any other reason is a STOP |

Never a separate bookkeeper or commit agent: each costs ~60k tokens of context for one
`git commit`. (Measured: a serial run spent 19% of its tokens on 9 one-line commit agents
and 70% of its wall-clock on slices run one after another.)

**Bead writes have one owner.** Inside a workflow, only the agent whose brief assigns it a
bead writes to that bead (`bd update`/`bd close`, notes, the frozen page in its text), and
only when the brief says so: the per-slice agent for its slice, the code architect for its
milestone's pages, the fix agent or the run's closing step for a blocked or closed status.
Nobody in a workflow creates or claims a bead or runs `bd remember`. Outside a workflow the
main loop writes beads; while a workflow runs it does not hand-run them.

**Once, at the end — when the change's last slice is pushed, in parallel, over everything
(BASE..HEAD), never per slice, lane or milestone:**

| Step | Who | Rule |
|---|---|---|
| CI watch | a watcher agent | blocks on the PR's checks (the full gate, incl. e2e); reports pass/fail with the failing excerpt |
| Verify | verifier | mutation probe per acceptance criterion (restored and rebuilt per the verifier body); conformance to each slice's frozen page; both branches of new conditionals driven; no full local verify |
| Review | lenses in parallel | security lens when §2.3 applies, plus the risk-relevant others; findings need file:line or a probe; non-code findings cannot fail a slice |
| Fix | ONE agent | applies the surviving findings, re-runs its changed-package checks, pushes; CI watched again. The round is checked narrowly: each finding's test and its mutation, never a full re-verify or a fresh review |

A full local verify runs only when `rules:global` §Delivery allows it; then in the
foreground, once.

Fix cycles: at most two per gate. After the cap:

- verification still red for a **code** reason → save the work as a pushed
  `wip/<bead>` branch, mark the bead blocked with the findings, **stop the run** and
  report. Do not revert-and-continue to the next bead.
- red because the **cut** is wrong (a spec/DAG contradiction, a consumer owned by a
  later bead) → stop immediately, re-cut per §3, restart from the saved branch.
- red only on docs or style → land it; cut a `residual:` bead.

Two consecutive stops on different beads = the cut is wrong; re-slice before any
further implementation.

## 5. Budget gates (hard; the run stops itself)

Set these in the run brief before launch; the loop enforces them:

- **Per bead:** wall-clock ceiling (default 90 minutes) and agent ceiling (default 8).
  Exceeding either = stop after the bead, report.
- **Per feature:** token ceiling and wall-clock ceiling from the sizing step. At 80%
  the loop posts a warning milestone; at 100% it stops after the current bead.
- **Per run:** a session-quota wall or a repeated environment failure (exit 134 heap
  abort, install/dist mismatch) = stop and report, never retry in a loop. A model or
  rails change mid-run = stop after the current bead lands, then relaunch; never
  re-pin a live loop (it invalidates the run cache and orphans in-flight work).

Reporting is a comment on the feature PR with: beads landed (id, sha), beads
stopped (id, branch, findings), open errata, next ready beads, tokens and hours spent.

## 6. Environment preflight (before any unattended launch)

Run with the **exact** command prefix the loop will use, and paste the results into
the run brief. Do it once; a setup step that already ran a check counts.

1. Pinned runtime on PATH (`.nvmrc` or equivalent) — the shell default is often wrong.
2. Heap and memory: set the interpreter heap flag the lint/test tools need under
   load; check host contention (other sessions, browsers).
3. `node_modules` matches the lockfile (spot-check one platform binary's version);
   dependent `dist`/artifact matrices rebuilt and fresh.
4. Baseline: the branch tip's latest CI result (green, or the known-red set pinned by name).
   Run a local baseline only when CI has no verdict.
5. Hooks known: which run on commit and push, which are zombies, what may be bypassed
   (usually only `--no-verify`, only when the hook re-runs what the agent already ran).
6. Services the tests expect (Docker daemon, databases) present or explicitly absent.
7. Models pinned by full id, per `rules:global` §Always; `haiku` only for pickers and
   bookkeeping.
8. Quota window known; do not launch a multi-hour run an hour before a reset.

## 7. State on disk, always

- Ledger (bead, outcome, sha) and `COHERENCE-BASE` markers, committed.
- `.claude/errata.md` append-only (read with `grep -a`; it may hold NUL bytes).
- Every failed or interrupted attempt as a pushed `wip/<bead>` branch — never only a
  scratchpad diff. Untracked files are part of the attempt. Save it through a private index, which
  leaves the shared index, HEAD and branch alone and takes only the paths named (the slice's
  owned list; `.` for an agent alone in its checkout):
  ```bash
  export GIT_INDEX_FILE="$(git rev-parse --absolute-git-dir)/index.wip-<bead>"
  git read-tree HEAD && git add -A -- <owned paths> &&
    git push origin "$(git commit-tree "$(git write-tree)" -p HEAD -m 'wip(<bead>): <why>'):refs/heads/wip/<bead>"
  rm -f "$GIT_INDEX_FILE"; unset GIT_INDEX_FILE
  ```
- To land a stranded `wip/` branch: `git cherry-pick -n` it and commit under the repo's commit
  convention (a `wip(...)` type fails a Conventional Commits lint).
- Bead notes carry the pointer to the branch and the open findings so the next
  implementer resumes instead of restarting.
- Agents return reports and findings in their result value; the script or the main loop
  writes the files. `design-reviewer` cannot write, and other agents are sometimes refused;
  a step that reads an agent-written file must fail loudly when it is missing.
- Orchestrator memory holds the resume pointers (branch, script path, ledger), not
  the detail.

## 8. Handoff

A run ends (planned or by a gate) with: the ledger committed and pushed; `wip/`
branches for anything unlanded; bead statuses honest (`open`, `blocked`, or `closed`,
never a stale `in_progress`); a PR comment per §5; and a "start here" for the next session.

A run that pauses for more than a few hours (usage, an owner gate) leaves a cold-start
`HANDOFF.md` next to its working state. A workflow's resume cache only works in the same live
session; assume a fresh agent picks up the next milestone. The handoff covers:
the problem in plain words; the reading order (which files are current, which are history);
precedence among the sources; the state (commits, beads, open findings); the next milestone and
exactly how to launch it; the binding owner rules and environment pitfalls; open questions.
Test it with a cold-reader agent given only that file. Scope each launch to one milestone; the
end review (§4) runs in the launch that lands the last slice.
Point the bead notes and memory at the handoff.

## 9. Workflow scripts: operational gotchas

- **Liveness.** Workflows can die silently (empty task registry, 0-byte output). Arm a liveness
  monitor in the main loop: stall over 15 minutes → stop and resume (`resumeFromRunId`, same
  live session only). An agent's transcript stays silent through a ~6-minute full test run, so
  never set the threshold lower. On macOS `find` is `bfs`, which rejects
  `-newermt '-900 seconds'` and matches nothing (a false stall every cycle); age-check with
  `stat -f %m "$DIR"/* | sort -n | tail -1` against `date +%s`.
- **Agents never background a long command.** An agent that backgrounds verify/test or arms a
  Monitor ends its turn without calling StructuredOutput and the workflow errors. Put a rails
  line in every script: run it FOREGROUND in one Bash call with a long timeout and wait.
- **Long logs.** Route test/verify output through `${CLAUDE_PLUGIN_ROOT}/scripts/verify-quiet.sh <cmd...>` (prints
  only RESULT=PASS, or RESULT=FAIL plus filtered failure lines); a passing 2,000-line log is
  the biggest token sink.
- **`args` may not reach the script.** Bake the run's config into a per-run copy of the script
  as the `cfg` defaults and invoke it by `scriptPath` with no args.
- **No backticks inside backtick-delimited prompt literals.** Validate with
  `cp script.js /tmp/x.mjs && node --check /tmp/x.mjs`; the only expected error is
  "Illegal return statement".
- **Why resuming breaks on edits** (the rule is `workflow:orchestrator` §Workflows). Editing
  a prompt builder shared by every bead, or a parallel workflow (its interleaved agent order
  breaks the cache's longest unchanged prefix), re-runs finished steps live: one resume re-ran
  four landed beads (~75 min), another re-committed finished work.
- **An empty review result is a FAIL, never zero findings.** The script fails closed and reads
  the verdicts before trusting a result: an empty one can be a crashed agent, and "rejected" after
  an interruption can mean a gate step died, not that the change failed. A finder's zero: §10.

## 10. Refactor work

Refactoring is ordinary work under this skill (owner, 2026-10-09: "these 'ralph loops' seem like
overly specific versions of my generic workflow preferences"). Only how the work is found
differs: a read-only finder lists candidates toward a target idiom. The finder stands in for §1
(the design document, its review and the tracer) and for §2.1's slice list; everything else
holds, including the code architect's frozen page per slice (§2.2) and the security lens (§2.3).
Candidates batch into few large slices (§3; a whole domain per slice, not one property) that
land, fan out, and are verified, reviewed and fixed once at the end per §4; a red that outlasts
the fix cycles is saved to `wip/` and stops the run, never reverted to continue.

- **The scope is the owner's.** The target idiom, the cost ceiling and the off-limits list are
  what he picks at the sizing step (`workflow:orchestrator` §Design-first pipeline); keep
  them in one editable place. A candidate that fires a sizing trigger there (a new package
  boundary, a cross-package edge, security or authz) is an owner gate under that pipeline, never
  a tier the run climbs alone: the run leaves it uncut and names it in its report.
- **Pin the known-failure baseline first** (§6.4; each failure proved pre-existing per
  `rules:global` §Always) and judge every push by "no new failure", or a regression hides
  in the ambient red.
- **Unblock the gate before anything.** A red early stage that halts the chain (a type error, an
  `&&`-chained verify) leaves the later stages unrun, not green. Fix it as the first slice.
- **Find what is not yet in the target idiom**, not only defects: a defect hunt reports
  exhaustion early.
- **Tiers of rising cost:** correctness fixes, idiom cleanups, conversions, then module
  extraction. When a tier drains, re-point the finder at the next, up to the owner's ceiling; a
  dry finder at one tier says nothing about the next.
- **A finder's zero has three meanings** (§9's fail-closed rule, for finders): with a stated
  reason (file:line) it is a drain; after an early death it is a crash, rerun at the same tier;
  with findings it is a defective plan, fixed before the next slice is cut.
- **The finder can block.** It, or the code architect writing the batch's pages (§2.2), may
  answer "not a clean slice; here is the blocker" (a missing prerequisite, a live path the change
  breaks) and leave the candidate uncut, the blocker in the run's report. No scoping agent per
  candidate.
- **Read an issue's notes before calling a candidate owner-blocked.** A later owner answer can sit in
  the notes while the description still says "unresolved"; finders reading only descriptions
  skipped a whole decomposition for a phase. The bead's writer (§4) corrects the description.
- **Behaviour-preserving covers more than the value.** Test the trickiest valid input. Rewiring
  (a DI token, an import, an init order) keeps the ordering and side effects the old wiring
  implied, such as validation that used to run first.
- **A deletion's doc scope is every file naming the deleted symbol**, not the diff; checks pass
  stale docblocks.
- **Autonomy.** While checks pass, a run does not send design-preference choices back to the
  owner; over-asking defeats an unattended run. A fork he must own (a public contract, security,
  a frame or design contradiction) follows the rules that already cover it: errata and stop (§4),
  or, at a gate with no one present, persist, notify and END (`workflow:orchestrator`
  §Design-first pipeline).
- **Sizing (§5).** The one measured figure is the retired loop's: about 0.5-1M tokens per
  decomposition chunk of 1-2 units, under the per-candidate ceremony §4 removes. Re-measure on
  the first run under §4.

The retired loop's per-candidate review, local full verifies, serial-only writes and
land-or-revert are overridden by §4. Its notes, superseded: `reference/archive/refactor-ralph-loop.md`.

## Pre-launch checklist

- [ ] Design doc merged or explicitly accepted; tracer defined; its mutation probes on the
      tracer slice's page. Refactor work: the owner's scope instead (§10).
- [ ] Slices listed, few and large; the tracer slice is first; each slice's frozen page is in its bead.
- [ ] Every bead passes §3.1 green-alone and §3.2 co-change on paper.
- [ ] No bead spans more than two packages; none is under an hour or over the per-bead ceiling (§5).
- [ ] Slices with disjoint files (derived outputs counted) marked to run concurrently, each with
      its owned files and its path-naming land command (§4).
- [ ] Docs beads separate; no coherence bead per layer; verify, review and fix once, at the end.
- [ ] CI watcher step present; no local full verify unless `rules:global` §Delivery allows one.
- [ ] Budget gates written into the brief (§5).
- [ ] Preflight results pasted (§6), models pinned by id (`rules:global`).
- [ ] Ledger exists; handoff format agreed (§8).
