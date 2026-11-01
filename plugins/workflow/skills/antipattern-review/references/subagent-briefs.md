# Subagent brief templates

Copy-paste starting points. Fill the `<...>` slots. Spawn all read-only, in the background,
in parallel. Use a capable model (the reasoning matters); do NOT spawn many identical
agents — one distinct lens each.

The two things that make a brief produce evidence instead of vibes are the **METHOD**
(names the grep patterns / CodeGraph queries so the agent doesn't flail) and the **RETURN
contract** (conclusions not dumps, `file:line` for everything, short quotes, no diff pastes,
CONFIRMED vs SUSPECTED, negative space). Keep both in every brief.

---

## Triage brief (spawn ONE; produces the dispatch agenda)

```
You are a senior code reviewer doing an ADVERSARIAL anti-pattern TRIAGE of a large change.
Your job is NOT to fix and NOT to review line-by-line — it is to survey the whole change and
return a RANKED LIST OF DISTINCT ANTI-PATTERN CLUSTERS, each with enough evidence that a
follow-up agent can be dispatched to hunt every occurrence.

Repo: <path>
Target: `git diff <base>...<head>` (<N files, +X/-Y>). Hotspots: <top packages/dirs>.
<If canaries:> The owner flagged these examples (dedicated agents already own them — do NOT
deep-dive them, but note if you see the SAME class elsewhere): <canary list>.

Find the OTHER clusters — the owner suspects many. Sweep these axes (see the taxonomy):
leaky abstraction / layering; primitive obsession & tri-state; duplicated rules (esp.
security predicates); god functions; error handling / async / concurrency (fire-and-forget,
fail-open, TOCTOU); test theater; incoherent API surface; forked vocabulary (error codes /
events); speculative generality / dead code; naming drift; design-doc-citation coupling;
config/boot/magic values.

METHOD (be efficient): `git diff --stat` for hotspots; read the diffs of the largest/most
central changed files; skim tests for theater; use codegraph_explore for blast-radius when a
smell looks structural. Group into 4-8 DISTINCT clusters; merge near-duplicates.

RETURN (conclusions, not dumps) — per cluster: name + category; severity (structural/systemic
vs local) and rough occurrence count; 2-4 evidence anchors (file:line + a SHORT quote each);
one sentence of downstream consequence; whether it's the same class as a canary or NEW. Rank
most-systemic first. End with a one-line list of cluster names as a dispatch agenda. Cite
file:line for everything. No large diff pastes.
```

---

## Deep-dive hunter brief (spawn ONE per cluster/canary)

```
You are a <domain> reviewer doing a HOLISTIC hunt for ONE anti-pattern across a large change:
<ANTI-PATTERN NAME> — <one-line definition>.

Repo: <path>
Target: `git diff <base>...<head>`.

<If seeded:> THE SEED: <file:line + the exact smell + the owner's words if any>. This is not
one instance — it's a pattern. Find EVERY occurrence and trace its downstream consequences.

HUNT (from the taxonomy axis — tailor):
1. <the full blast radius of the seed: every type/site/consumer of this class>
2. <the logic variant, not just the data variant>
3. <the seam/architecture angle: which layer knows what it shouldn't>
4. <the second-order consequence: what rots / breaks / is admitted>

METHOD: start from the seed; codegraph_explore its blast radius; grep the diff for <the
specific patterns for this axis — see taxonomy>; follow the thread up (DTO/wire/UI) and down
(store/migration/runtime). Read the relevant spec only to confirm intent.

ADVERSARIAL RULES: assume more exists than the seed suggests; do NOT return "looks fine"
without having traced the risky paths; separate CONFIRMED (you traced/reproduced it) from
SUSPECTED; do not accept "it logs the error" as a mitigation for a must-succeed operation;
name the STRUCTURAL fix (what shape makes this class unrepresentable), not a per-instance patch.

RETURN (conclusions, not dumps):
  - Ranked list of occurrences: file:line + short quoted snippet + why it's an instance.
  - CONFIRMED vs SUSPECTED, clearly split.
  - Downstream consequences (what breaks / rots / is admitted).
  - The structural fix direction in 2-3 sentences (do NOT implement).
  - NEGATIVE SPACE: the risky paths you traced and found genuinely SOUND, so coverage is legible.
  - Total occurrence count.
Cite file:line for everything; quote snippets SHORT; no large diff pastes.
```

---

## Tuning notes

- **Seed as class exemplar.** When the user flags a spot, the seed slot gets their exact words
  and the `file:line`. The hunter's job is to prove (or bound) how far the class spreads.
- **For axes a prior pass dismissed** (error handling, test theater, layering are the usual
  under-weighted ones), add a line: *"a prior triage spot-checked this and called it fine; the
  repo's own reviewer then found a real defect here — assume more, trace don't skim."*
- **For test theater specifically**, tell the agent to reason about the surviving mutation
  ("if I delete line X of the SUT, does this test go red?") rather than running the suite.
- **For layering**, expect and welcome a clean result — a proven negative is a real deliverable
  that frames the other findings as legal within-layer smells.
- **Right-size.** If two agenda items would tread the same files (e.g. "provider-gate
  duplication" and "is-runner duplication"), give them to one "duplicated rules" hunter.
- **Model constraint reminder:** subagents use a capable-but-not-frontier model per the user's
  standing rule; pass the model explicitly, and never the reserved top-tier alias. Analytical
  hunts are fine on a mid-tier model; the *synthesis* stays in the main loop.
