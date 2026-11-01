# Retrospective: an unattended feature run (a private project, 2026-09-01 → 2026-09-02)

Historical reference for the `workflow:implementation-workflow` skill. Everything here is evidence from one run; the skill is what binds. The project-specific record stays with its project.

## What was attempted

One feature in a private project, designed in one document of record reviewed by the owner on a PR. It touched many packages.

## Timeline and cost

| Phase | Wall clock | Agents / tokens | Output |
|---|---|---|---|
| Design review + final revision (3 review lenses, 1 reviser, 1 consistency pass, 1 fix pass) | ~1.5 h | 6 agents, ~0.7M | One owner doc; all four owner comments addressed; one proposed mechanism withdrawn |
| Code architecture (draft → triad → 5 lenses × 2 cycles → closure check → targeted P0 revise → bead cut) | ~5 h (≈3 h of it a session-quota outage) | 20 agents, ~4.5M | One architecture doc several times the design's length, 45 DAG nodes, 64 beads |
| Implementation loop, run 1 (old rails) | ~4 h | 29 agents, tokens not totaled (run stopped; the runner reports usage only at completion) | 1 bead landed, 1 reverted, 1 in flight |
| Implementation loop, run 2 (another model, heap flag) | ~1.5 h | 16 agents, tokens not totaled (stopped) | 1 bead landed, 1 reverted |
| Stops, restarts, recovery, bead merge, review of what landed | ~1 h | 4 agents, ~0.3M | 3 WIP branches preserved; this retrospective |
| **Total** | **~13–14 h** | **~75 agents; ~5.5M tokens cited, ~7M estimated with the two stopped runs** | **2 of 64 beads landed (16 files, +808/−56)** |

## Failures and anti-patterns (with evidence)

1. **Beads cut along interface artifacts, not compile units.** One bead made every switch over a domain vocabulary total with `assertNever`, so *any* growth of that vocabulary fails to compile or fails a test until every consumer is updated. The cutter then put "add the vocabulary" (layer 0) and "update the consumers and their tests" (layer 2) in different layers. The vocabulary bead was implemented byte-for-byte to its frozen signatures and reverted because six of one service's tests, owned by the consumer beads, went red. A fresh-eyes reviewer confirmed that splitting the vocabulary bead from its consumer beads "is unsound under the per-bead green gate." *Rule: a bead that grows an enum or union carries its consumers and their tests.*
2. **Breadth-first layers across many packages.** Layer 0 spanned six packages. One bead touched 22 files across four packages. Each implementer/verifier/reviewer re-read the whole design and the much longer architecture before starting: ~100k tokens of context per agent, 5–9 agents per bead.
3. **Granularity far below the fixed overhead.** 64 beads; a rename bead paid the same 30–60 minutes as the decision-arm bead. Per bead: 3 full `verify:fast` runs (8–10 min each on a memory-contended host), dist rebuilds for cross-package mutation probes, two review lenses, bookkeeping. The code change itself was ~5 minutes of it.
4. **Docs inside the green gate.** "Build AND document" per bead coupled beads through README/CLAUDE.md/spec rows. Both P1s that killed one bead (green code, verified twice) were doc-consistency findings.
5. **Code-architecture phase bigger than the feature.** Freezing exact signatures for 45 nodes before any code: 20 agents, 46 review findings, two revise cycles, then a third targeted revise. The design doc's frame plus a per-slice interface freeze would have started implementation ~4 hours earlier.
6. **Green gate + revert destroyed finished work.** Two reverts of verified code; the loop then paid full price to rediscover the same coupling. Nothing in the loop distinguished "wrong code" from "wrong cut."
7. **Adversarial posture on trivial beads.** "A review that approves is a failed review" applied to a rename manufactures P1s, fix cycles and re-verification.
8. **Orchestrator restarts cost in-flight work.** A mid-run model re-pin invalidated the workflow cache and forced a restart; a heap-OOM baseline forced another; a session-quota wall stalled the architecture phase ~3 hours. In-flight untracked files had to be recovered from an agent transcript.
9. **Environment tax before any feature work:** the worktree's Node was not the pinned one, installed dependencies were older than the lockfile's, the linter ran out of heap under contention, a git hook hung. Each cost a baseline or a cycle.
10. **Wrong model alias.** The bare `opus` alias resolves to the latest Opus, not the model the run meant to pin. The direct Agent tool cannot pin `claude-opus-4-8` at all (enum), only the Workflow runner can.

## Successes and good patterns (with evidence)

1. **One design document per gate, reviewed by the owner on a PR.** The last revision cycle: the owner's four inline comments were all correct, and the doc-first shape made each one a paragraph to fix, not a module to rewrite. Kept binding.
2. **Adversarial, multi-lens review of the design, grounded in code.** Three lenses against the real code found a P0, a proposed mechanism that duplicated an identity the system already held (its whole section withdrawn), a frozen API surface that contradicted five of six proposed routes, and a database constraint the store could not add. A later closure check found a value with no frozen carrier between two layers. Every one of these was cheaper to fix as a paragraph.
3. **Tracer-first security spine as the ordering principle.** Never reached, but it is the right thing to prove first and the skill keeps it.
4. **Verification that trusts nothing.** Verifiers reproduced claims, ran mutation probes with dist rebuilds, and correctly refused a red `verify:fast` even when the code matched the spec. The failure they surfaced (the vocabulary bead) was real and was the DAG's, not theirs.
5. **State on disk, not in context.** Ledger, errata, saved diffs, bd notes and journal transcripts made every recovery possible, including reconstructing five deleted files from an implementer's Write calls.
6. **Preserving instead of discarding.** Failed attempts kept as diffs and re-fed as "prior attempt" notes; at handoff, pushed as `wip/<bead>` branches.
