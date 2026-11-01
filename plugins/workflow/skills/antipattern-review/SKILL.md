---
name: antipattern-review
description: >-
  Adversarial, multi-agent hunt for anti-patterns and design smells across a
  large change, PR, branch, or codebase — the "why is this code terrible?"
  review. Use this whenever the user asks to "review this", "tear this apart",
  "find the smells", "what's wrong with this code", "is this a mess", "do a deep
  / holistic / architectural review", or points at one or two bad spots and
  wants to know how deep the rot goes. Triggers even when the user names only a
  specific smell — treat their example as a canary and hunt the whole class.
  This is NOT line-level correctness triage (that's /code-review) and NOT a
  vuln scan (that's /security-review): it finds SYSTEMIC design smells —
  leaky abstractions, duplicated rules, god functions, primitive obsession,
  incoherent APIs, test theater, fail-open error handling, speculative
  generality, naming drift — clusters them, ranks them, and proposes structural
  fixes. Reach for it on any diff big enough that reading it linearly would
  miss the pattern.
---

# Anti-Pattern Review — "why is this code terrible?"

## What this is for

A linear read of a large diff finds line-level bugs and misses *systemic* rot: the
same leak repeated in eleven files, one weak type infecting every consumer, four
copies of a security check drifting apart. This skill finds the **classes**, not the
instances — it runs an adversarial triage, fans out one dedicated hunter per
anti-pattern axis, and synthesizes ranked clusters with structural fix directions.

It is an **orchestration** skill: you (the main loop) plan, dispatch read-only
subagents, and synthesize. You do **not** read all the source yourself — the agents
find things and report conclusions. This keeps your context for judgment, not file
dumps.

Complements, doesn't replace: `/code-review` (correctness bugs, effort-tiered) and
`/security-review` (vulnerabilities). Run those for "is it correct/safe"; run this
for "is it well-built, and where is it not."

## The core method (five moves)

1. **Seed from canaries — but never stop there.** If the user flags specific spots
   ("this is a domain leak", an inline PR comment, "this file is a mess"), treat each
   as a *class exemplar*: the visible tip of a pattern that almost certainly recurs.
   Name the class, then hunt every occurrence. If the user gave no seed, the triage
   pass generates the agenda from scratch.
2. **Triage into a dispatch agenda.** One adversarial agent surveys the whole change
   and returns a *ranked list of distinct anti-pattern clusters* — explicitly told to
   find clusters **beyond** any seeds. This is the agenda, not the answer.
3. **Fan out one hunter per cluster.** Each deep-dive agent owns exactly ONE
   anti-pattern and hunts it holistically: every occurrence + downstream
   consequences + the structural fix. Distinct lenses, never N identical reviewers.
4. **Adversarial posture, evidence-gated.** Every agent is forbidden to dismiss its
   area with a spot-check. Findings need `file:line` + a short quote. Separate
   CONFIRMED (traced/reproduced) from SUSPECTED. Demand **negative space** too — what
   was checked and found genuinely sound — so "thorough" is legible and false-clean is
   caught.
5. **Synthesize: cluster → rank → root-cause → deliver.** Merge overlaps, rank by
   severity (security/structural before cosmetic), give each cluster evidence +
   consequence + a fix that makes the *class* impossible, then name the 1–3
   cross-cutting root causes and report the verified-clean areas.

The philosophy behind moves 4–5 (make the failure class unrepresentable; prefer
compile-time > construction-time > boot > test > convention > comment; state costs;
a review that only approves is a failed review) is the house design philosophy — see
`references/anti-pattern-taxonomy.md` for how each axis applies it.

## Workflow

### 0. Scope and pin the target

Establish exactly what's under review and give every agent the *same* handle so
findings are comparable.

- **A PR / branch:** get the diff range. Prefer three-dot against the base:
  `git diff <base>...<head>` (changes on the branch since the merge base). Capture the
  merge-base SHA and the tip SHA so agents cite against a stable ref.
- **A working tree / uncommitted change:** `git diff` (or `git diff HEAD`). Say so —
  line numbers move.
- **A whole package / subsystem (no diff):** name the paths; agents review the current
  state, not a delta.

Then size it once, inline (don't spawn for this):

```bash
git diff --stat <base>...<head> | tail -1
git diff --name-only <base>...<head> | grep -v '\.md$' \
  | grep -oE 'packages/[^/]+|src/[^/]+' | sort | uniq -c | sort -rn
```

The hotspot list tells you where the epicenter is and helps you scope agent briefs.
Note whether the repo has CodeGraph (`.codegraph/`) — if so, tell agents to use it for
blast-radius.

### 1. Triage → agenda

Spawn ONE triage agent (read-only, capable model). Its job is the dispatch agenda, not
the fixes. Use the triage brief in `references/subagent-briefs.md`. Give it: the diff
range, the hotspots, any canary seeds (as *examples of the kind of thing to find*, with
a note that dedicated agents already own the seeds — find the OTHERS), and the taxonomy
of axes to sweep (`references/anti-pattern-taxonomy.md`). It returns 4–8 ranked clusters,
each with 2–4 evidence anchors and a one-line consequence, ending in a one-line agenda.

If the user gave strong canaries, you can launch the triage agent **and** a dedicated
hunter for each canary in the same batch — the canaries are already confirmed classes,
so their hunts don't need to wait for the agenda.

### 2. Fan out the hunters

For each cluster on the agenda (and each canary), spawn one deep-dive hunter, read-only,
in parallel in the background. Use the deep-dive brief template in
`references/subagent-briefs.md` and the per-axis hunt guidance in
`references/anti-pattern-taxonomy.md`.

Rules that make the hunters good (encoded in the templates — keep them):

- **One axis per agent.** Overlap is fine at the edges; a single agent chasing five
  smells returns mush.
- **Give it the seed, the hunt list, the METHOD, and the RETURN contract.** The METHOD
  names the grep patterns / CodeGraph queries; the RETURN contract demands conclusions
  not dumps, `file:line` for everything, short quotes, no diff pastes.
- **Forbid lazy dismissal.** Tell agents on areas a prior pass waved off ("looks fine"):
  assume more exists, trace the risky paths, and don't accept "it logs the error" as a
  mitigation for a must-succeed operation.
- **Demand the structural fix**, not the patch: what SHAPE would make this smell
  unrepresentable (a discriminated union, one exported predicate, a boot check).
- **Right-size the fleet.** A dozen axes is thorough; don't spawn identical agents. Merge
  axes that would tread the same files (e.g. one "duplicated rules" agent covers all
  copied predicates). Typical run: 1 triage + 8–12 hunters.

Don't read the agents' raw transcripts — wait for the completion notifications and read
the conclusions.

### 3. Second wave (usual, not optional)

The triage agent under-weights or misses things — that's expected, it's a survey. When a
hunter surfaces a *new* cluster the agenda didn't have (a forked error vocabulary hiding
inside the API-coherence hunt, say), spawn a dedicated hunter for it. Also spawn hunters
for any taxonomy axis the triage skipped that the change plausibly touches (error
handling/concurrency, test theater, and layering are the ones triage most often
short-changes). Push here if the user says "don't be lazy" or "there's more" — add axes,
don't re-run the same ones.

### 4. Synthesize and deliver

Write ONE ranked report (structure in `references/report-structure.md`). For the owner,
this technical report is working state; what he reads is the user-impact report below.
Essentials of the technical report:

- **Bottom line up top:** how many clusters, whether any are security-relevant vs
  cosmetic, and the single most important thing.
- **Severity-ranked table**, then one section per cluster: what it is, evidence
  (`file:line`), the downstream consequence, the **structural fix direction**, and
  whether it's CONFIRMED or SUSPECTED.
- **Root causes:** the 1–3 cross-cutting structural decisions that generate most of the
  clusters. This is the highest-value part — fixing a root cause dissolves many
  instances. (In practice most clusters ladder up to two or three: "one case modeled
  without a real seam", "each feature invented its own vocabulary", "process artifact
  shipped as code".)
- **Negative space:** what you verified is genuinely clean (layering, DI, compat), so
  the coverage is trustworthy and not just a pile of complaints.
- **Prioritized action order:** what to land now (small + security), what to decide
  before an interface freezes, what to schedule, what's opportunistic hygiene.

**The owner-facing report (BINDING for the owner, 2026-10-02/03).** He decides fix-the-cause
versus patch-the-symptom from user impact, and won't patch a bug without knowing why it
exists. A technical cluster list, or 27 finding cards, is rejected. Brief the synthesizer to
produce this shape directly, under a hard length cap:

- **Product areas first:** the user features involved (what they do, for whom).
- **3-6 classes of user-visible behaviour**, each: what the user experiences when it goes
  wrong, who notices and when, how bad (serious / noticeable / latent / internal), WHY it
  exists in plain words, and what fixing it changes for users.
- **The 1-2 design flaws behind them, developed:** what each is, why the structure admits it,
  the remediation shape and how it makes the class impossible. This is the deepest part.
- **Findings only as one-line examples** proving a cause; the full list stays in working
  state. Many findings is itself the signal of a design flaw, not a longer list.
- Lead with a one-screen summary table ordered by user impact; technical cluster ids in
  small print only.

Deliver it as a published page (Artifact), or a file in the repo the owner can open, never a
file in a hidden config folder. A synthesizer subagent returns the text in its result and
the main loop publishes it. Then give a tight spoken summary leading with the
security-relevant findings. Offer concrete next steps (post as PR review, file issues, spec
the top fix test-first) rather than trailing off.

## Calibration — don't cry wolf

Thoroughness is the point, but a report that flags everything is as useless as one that
flags nothing. Hold the bar:

- **Distinguish a smell from a documented, costed decision.** A single-implementation
  interface at a module boundary, a well-factored module with one consumer today (DRY and
  SOLID, `rules:global`), an enum member named-but-not-wired with a fail-closed gate
  and a test, a deliberately-duplicated check with a mutation-probe guarding each copy —
  these are often *correct*. If the code states the cost and the reconciliation plan,
  say "justified", don't pad the count. The agents should return negative space for
  exactly this reason.
- **Rank by blast radius and reversibility.** A fail-open security regression that no
  test catches outranks a naming inconsistency, always. Lead with what bites.
- **Prefer one proven finding to five suspected.** Suspicions go in a clearly-labeled
  "suspected" bucket, not the headline.
- **Fix the class, not the instance.** Every recommendation should move a property up the
  guarantee ladder (compile-time > construction > boot > test > convention > comment). If
  the "fix" is a new convention someone must remember, it isn't one.

## Reference files

- `references/anti-pattern-taxonomy.md` — the catalog of axes to sweep, what to hunt for
  each, seed examples, grep patterns, and the structural fix each points to. **Read this
  before writing the triage brief** — it's the checklist that makes the sweep complete.
- `references/subagent-briefs.md` — copy-paste brief templates for the triage agent and
  the deep-dive hunters, with the METHOD and RETURN contract that make agents return
  evidence instead of vibes.
- `references/report-structure.md` — the synthesis/report template and a worked severity
  ranking.
