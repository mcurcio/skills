# Report structure

Write ONE ranked report (it outlives the terminal and is shareable — paste as a PR review,
hand to an implementer). For the owner it is working state: the owner reads the user-impact report
(SKILL.md §4 and "Owner-facing report" below). Then give a tight spoken summary that leads with
the security-relevant findings, not the cosmetic ones.

The report's value is in the ranking and the root-cause synthesis, not the raw finding count. A
reader who reads only the bottom line and the severity table should already know what to fix
first and why.

## Template

```markdown
# <Target> — Anti-Pattern Review

**Target:** <PR link / branch / paths> — <N files, +X/-Y>.
**Method:** triage → <K> dedicated deep-dive hunters, one per anti-pattern axis, each hunting
all occurrences + downstream consequences. <Seeds, if any> were seeds, not the scope.

## Bottom line
<2-4 sentences: how many clusters; whether any are security-relevant vs aesthetic; the single
most important thing; the one root cause that explains most of it.>

### Severity-ranked clusters
| # | Cluster | Class | Severity | Occurrences |
|---|---------|-------|----------|-------------|
| 1 | <name> | <e.g. reliability/security> | P1 | <count> |
| ... |

**Clean (verified, no action):** <the axes that came back sound — layering, DI, compat, etc.>

## <N>. [Severity] <Cluster name>
<What it is, in one line.>
- `file:line` — short quote — why it's an instance.  (repeat for the key occurrences)
**Failure scenario / consequence:** <concrete: "if X fails after Y, then Z leaks/denies wrongly">
**Fix direction:** <the STRUCTURAL fix — what shape makes the class impossible>. CONFIRMED / SUSPECTED.

## The root causes (fix the class, not the instances)
1. <cross-cutting decision #1 and which clusters it generates, and the one structural change that dissolves them>
2. ...

## Suggested action order
1. **Land now (security + small):** <clusters>
2. **Decide before <interface/API> freezes:** <clusters>
3. **Structural, schedule deliberately:** <clusters>
4. **Hygiene, opportunistic:** <clusters>
```

## Ranking rules

Order clusters by **blast radius × reversibility**, not by how egregious they look:

1. **Security-relevant + confirmed** first — a fail-open regression no test catches, a leak with
   no TTL, an abuse control defeated by concurrency. These bite in production.
2. **Test/verification holes** next — they're why the security ones shipped; small to fix.
3. **Structural leaks** that block the next feature or freeze into an interface — high cost to fix
   later, cheap to decide now.
4. **Coherence / DRY** — real maintenance tax, not an outage.
5. **Cosmetic / naming / docs** last — real, but never ahead of the above.

## The three-root-cause pattern

Most large single-feature changes ladder up to two or three cross-cutting causes. Naming them is
the highest-leverage part of the report — fixing a root cause dissolves many clusters at once.
Recurring shapes worth checking for:

- **"One case modeled without a real seam."** Generates the abstraction leak, the primitive
  obsession, the duplicated per-case gates, the dead speculative generality, the case-specific
  naming. Fix: the discriminated-union / case-owned-extension refactor (often the codebase already
  has the right pattern elsewhere).
- **"Each feature invented its own vocabulary."** Generates the incoherent API surface, the forked
  error codes, the naming drift. Fix: authority artifacts — a URL scheme, one error enum, a glossary
  — not per-route edits.
- **"Process artifact shipped as code."** Generates the citation-comment coupling, the god functions
  (review scaffolding inlined), and much of the diff size. Fix: inline the load-bearing rationale,
  push provenance to git history, decompose.

## Owner-facing report

Same evidence, organized for a decision in user terms, under a hard length cap:

```markdown
# <Target> — what goes wrong for users, and why

## Summary (one screen, ordered by user impact)
| Class of user-visible behaviour | Who notices, when | How bad | Root cause |
|---|---|---|---|

## Root cause 1: <design flaw in plain words>
What it is. Why the structure admits it. The remediation shape, and how it makes the class
impossible. Examples: one line each (`file:line` in small print).

## Root cause 2: ...

## Product areas affected
<feature: what it does for whom; which classes touch it>
```

## Delivery

- Publish the owner-facing report as a page (Artifact), or put it in a file in the repo the owner
  can open; never a hidden config folder. A synthesizer returns the text; the main loop
  publishes it. The technical report stays in working state.
- Lead the spoken summary with the security findings and the action order — not a recap of method.
- Offer concrete next steps: post as a PR review comment, file issues for the top trio, or spec the
  #1 fix test-first for an implementer. End on a choice, not a trail-off.
