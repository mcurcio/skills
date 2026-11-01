# Anti-Pattern Taxonomy — the axes to sweep

The checklist that makes the hunt complete. Each axis is a distinct lens; give each its
own hunter (or merge two adjacent ones when they'd tread the same files). For each axis:
what the class is, what to hunt, starting points (grep, and `codegraph_explore` only where the
repo has a CodeGraph index, `.codegraph/`), and the **structural
fix** it points toward — because the goal is always to make the class unrepresentable,
not to patch one instance.

Not every axis fires on every change. Use the diff's hotspots to pick: a credential/auth
PR lights up abstraction-leak, duplicated-rules, error-handling, test-theater; a UI PR
lights up god-components, primitive obsession, naming drift. Sweep the plausible ones;
don't spawn a hunter for an axis the change can't touch.

## Table of contents

1. Leaky abstraction / domain leak
2. Primitive obsession & tri-state data
3. Duplicated rules (esp. security predicates)
4. God functions / long methods / god components
5. Error handling, async & concurrency
6. Test theater
7. Incoherent API / resource surface
8. Forked vocabulary (error codes, events, status)
9. Speculative generality / half-built abstractions / dead code
10. Layering & boundary integrity
11. Naming & vocabulary drift
12. Design-doc / process-artifact coupling in code
13. Config, boot & magic values

---

## 1. Leaky abstraction / domain leak

**Class.** A specific case's concerns bleed into a layer that's supposed to be generic —
provider-specific fields on a generic record, one vendor's vocabulary threaded through
"provider-neutral" code.

**Hunt.** Every type/interface/DTO/column/migration living in a generic-named home
(`credential`, `store`, `record`, `api`) that carries case-specific fields. Generic layers
that branch on `provider === 'X'` or hardcode a host/vendor constant. A "generic"
abstraction only ever exercised by one concrete case (that's also axis 9). Follow the leak
*up* (DTO → wire → UI) and *down* (record → migration → runtime).

**Starting points.** `codegraph_explore` the flagged type + its producers/consumers; grep
the diff for the vendor name, hardcoded hosts, `provider ===`.

**Structural fix.** Split the flat shape into a discriminated union at the boundary; move
case-specific fields into a case-owned extension record behind a seam the generic layer
never imports. A second case becomes "one more table + one more policy", never a touch to
the generic file. *Check first whether the codebase already has the right union one field
over* — leaks often sit next to the correct pattern.

## 2. Primitive obsession & tri-state data

**Class.** A real domain concept degraded to raw `string`/`number`; `optional?: T | null`
fields that hide a record-kind or a three-state (absent/null/value) ambiguity.

**Hunt.** Enum-to-string degradation across a seam — a value typed as an enum at one layer
becomes `string` at another (a typo then type-checks through). `field?: T | null` on a
persisted/wire type: do absent and null mean different things? If not, ambiguity; if yes,
an unmodeled union. Stringly-typed ids with embedded kind prefixes (`id.startsWith('x:')`).
Boolean blindness (three booleans where a state enum belongs). A fabricated fallback literal
is a tell — it means the type didn't force the author to prove the case.

**Starting points.** Grep `: string | null`, `?: .*| null`, `as <Enum>`, `.startsWith(`,
`z.enum`; trace where a strong upstream type becomes weak downstream.

**Structural fix.** Branded types / discriminated union with a `kind` tag / the enum at the
store boundary derived from a single source of truth. Replace bare `as Kind` casts with a
validating `parseKind` that throws on garbage (fail-closed at the row boundary).

## 3. Duplicated rules (especially security predicates)

**Class.** The same rule re-implemented in N places instead of one home. Each copy correct
today; the risk is drift and a fail-open regression in one arm the others' tests don't catch.

**Hunt.** Copy-pasted predicates — the same discriminant (`x.kind === Kind.Runner`, an
owner-match, a scope check, a host/SSRF allow-list) inlined at multiple sites. The same rule
re-derived at two *type layers* (post-resolution vs pre-resolution). Look for the
**forbidden-idiom** variant too: if docstrings say "read the field, never the string prefix",
grep for code that uses the banned test — that's a correctness divergence, worse than DRY.
Rank by which copy, if it silently flipped fail-open, is covered by no other copy's tests
(bypass paths are the danger).

**Starting points.** `codegraph_explore` each predicate for all call sites; grep the enum
value, the forbidden idioms, `.has(`, allow-list constant names.

**Structural fix.** One exported predicate imported everywhere; or a type that makes the
wrong test unrepresentable. For rules that must track a set (allow-lists), a boot-time
assertion that the copies agree (construction-time impossibility).

## 4. God functions / long methods / god components

**Class.** One function fuses many independent concerns (authz + validation + I/O + crypto +
persistence + audit + response-shaping), so no concern is independently testable and the
companion test is combinatorial.

**Hunt.** Functions over ~80 executable lines or with ≥3 fused concerns. Map the
concern-blocks to line ranges. Note whether the test file is oversized as a direct
consequence (standing up the full dependency graph to hit one branch). Crucially: are the
seams already near-pure (evidence the fusion is *incidental*, i.e. the same codebase
decomposes cleanly elsewhere)? Capture ordering constraints that a naive extraction would
drop (a cheap check that must precede an expensive network call; an id minted immediately
before it's used as crypto AAD).

**Starting points.** `git diff --stat` for big changed files; read the top handlers; grep
for the concern markers (validation, encrypt, persist, audit, `res.json`) clustering in one
function.

**Structural fix.** Extract named steps / a pipeline, each independently testable,
preserving the documented ordering. Point at where the same PR already did it right.

## 5. Error handling, async & concurrency

**Class.** Fire-and-forget on must-succeed operations; swallowed errors; fail-open where
fail-closed is required; TOCTOU / races on check-then-write.

**Hunt.** `void asyncThing()` / un-awaited promises / `.catch(()=>{})` where the operation
*must* eventually succeed (revocation, rotation, audit, cleanup) — a logged failure is not
the operation happening; is there a retry or reconciliation sweep, or does a transient fault
leak state forever? Error paths on security decisions that *admit* rather than deny. Default
returns that look like "no result" when they were really "lookup failed" (fail-open wearing
fail-closed's clothes). Check-then-write without a transaction/unique-constraint (can N
concurrent callers each pass a cap check before any write lands? widen the window with any
network hop between check and write). Idempotency of recovery/restart paths.

**Starting points.** Grep `void `, `.catch(`, `catch (`, `Promise.all`, missing `await`,
"best effort", "fire-and-forget"; trace cap/grant/revoke/rotate write paths for atomicity;
find the recovery/sweep functions and check what they *scope to* (a terminal-state record is
often invisible to a sweep that only inspects active state).

**Structural fix.** Outbox row written in the same transaction as the state change, drained
with retry; reconciliation sweep that diffs desired vs actual; DB unique constraint / row
lock so the cap is enforced at the write. Don't accept "it logs" as a mitigation.

## 6. Test theater

**Class.** Tests that would still pass if the code were wrong.

**Hunt.** Assertion-free / tautological tests (`toBeDefined` as the only check on a security
path). Over-mocking that hollows the SUT (a fetch stub that ignores the `RequestInit`, so
deleting the auth header keeps every test green — *reason about the surviving mutation*).
Guard tests whose assertions survive deleting the rule they're named for. Skipped/`.only`/
`todo`/commented-out assertions. **Typecheck holes** — spec files excluded from `tsc` (a
planted `number = "string"` passes) — find the tsconfig excludes and which packages are
blind. Coverage-as-theater (high line coverage, the deny/error branch uncovered). Check the
repo's own test DoD (fixtures via the validated factory, real migrated DB, no `as any`).

**Starting points.** Grep `.skip`, `.only`, `.todo`, `xit`, `expect(true`, `toBeDefined`,
`vi.mock`, `as any`, `eslint-disable`; open the biggest new specs; read `tsconfig.build.json`
excludes and the `typecheck:test` target. Reason statically — don't run the suite to judge
theater.

**Structural fix.** Assert the real effect (the header on the wire, the row in the DB); bring
excluded specs under typecheck; drive both branches of every conditional.

## 7. Incoherent API / resource surface

**Class.** Routes, resources, verbs and paths invented per-feature with no unifying scheme.

**Hunt.** Inventory every new/changed route (method + path + purpose + auth) from *both* code
(controllers/decorators) and spec. Then: actions-as-paths (`/value`, `/status`) where a
resource GET would do; the same concept under two prefixes; inconsistent nesting/pluralization;
`/me` conflating identity with a collection; query-vs-path-vs-subresource inconsistency; verbs
that break REST semantics; response *polymorphism on one address* (caller identity silently
changes the body). Code-vs-spec divergence is itself a finding.

**Starting points.** Grep route decorators / registrations; read the spec's route tables;
`codegraph_explore` the controllers.

**Structural fix.** One noun per resource (type as a field/filter, never a prefix); identity
via a single `GET .../me`, ownership as a filter on the normal collection; one lifecycle-action
convention documented as the house style; never let caller identity change a contract silently.
Do it holistically *before the surface freezes*.

## 8. Forked vocabulary (error codes, events, status)

**Class.** A second, parallel vocabulary introduced beside the canonical one — a new error-code
grammar, event-name scheme, or status set with no stated relationship to the existing enum.

**Hunt.** Every error-code/event/status string the change introduces; the canonical mechanism
it bypasses (the shared enum, the one envelope shape). Whether the two ever collide or a client
can tell which grammar a response uses. **Internal** consistency of the new vocabulary
(casing/shape drift). Multiple wire *shapes* for one nominal vocabulary depending on which
handler catches it (the worst case — the code is present, dropped, nested, or top-level by
accident of call site). Duplicated status-maps already out of sync.

**Starting points.** Grep the new code shape (`'<word>.<word>.<word>'`, new event names); read
the canonical enum and the error filter that maps code → HTTP.

**Structural fix.** One owned vocabulary (extend the enum or a documented sibling), machine
detail in a `detail` field, one generated status-map, every response through the canonical
envelope.

## 9. Speculative generality / half-built abstractions / dead code

**Class.** Surface nothing exercises: enum arms/branches never reached; unused exports;
knobs only ever set one way; backwards-compat shims that default to old behavior (this user
wants the new behavior to *be* the behavior).

**Not this class** (DRY and SOLID, `rules:global`): an interface with one
implementation at a module boundary, or a single-responsibility module with one consumer today.

**Hunt.** Enum arms / switch cases nothing constructs; "Phase 2" stubs with an unreachable
branch. Unused exports (CodeGraph blast-radius 0). Parameters only ever passed one value; mode
switches no caller flips. `if (legacy)` / `?? oldBehavior` / feature-flags-defaulting-to-old.
An interface whose contract leaks its one implementation (shallow, a knob per behavior) is a
*leaky abstraction* (axis 1), not speculation.
**Verdict each item**: DEAD/SPECULATIVE (remove the unexercised surface) vs JUSTIFIED (a real
boundary or responsibility, or forward vocabulary guarded fail-closed with a test).
Judge whether the surface is *exercised*.

**Starting points.** Grep the not-yet-real enum members, `TODO`/`FIXME`/`Phase`, `legacy`,
`fallback`, `?? `; `codegraph_explore` each suspicious export or enum member for callers
(blast radius 0 means unused).

**Structural fix.** Delete the speculative surface; keep forward-looking *vocabulary* only when
it's guarded fail-closed and tested. No compat toggles — reversibility is `git revert`.

## 10. Layering & boundary integrity

**Class.** Forbidden cross-layer/sibling imports; concrete-class dependencies across seams;
suppressions that hide a boundary breach; DI bypassed.

**Hunt.** Every new cross-package `import`, classified against the repo's boundary rules (the
lint config's element matrix is the source of truth). `eslint-disable` for `boundaries/*` or a
suppression next to a cross-package import. Concrete classes imported where the interface exists.
DI smells (`new` of a cross-boundary dependency outside the composition root, module-level
mutable singletons, a hardcoded env value in composition instead of injected config). New
interfaces missing the repo's prefix convention or re-declaring a contract that exists a tier up.
Migrations coupling two services' schemas.

**Starting points.** Filter the diff to `+import` lines; read the boundary matrix; grep
`eslint-disable`, `new [A-Z]` across seams, module-scope `let`. **This axis often comes back
clean** — that's a valuable negative result: it proves the smells are legal within-layer design
issues the matrix can't catch, not import-graph breaches.

**Structural fix.** Depend on the interface; construct concretes only at the composition root;
inject config; keep the boundary lint un-suppressed.

## 11. Naming & vocabulary drift

**Class.** The same concept under different names across files; casing/pluralization drift; each
feature coining its own idiom where a house style should exist. (The code-level analog of axis 7.)

**Hunt.** Synonym clusters — build them from the diff (grant/binding/role-binding;
principal/owner/caller; validate/probe/verify; revoke/delete/withdraw) and judge each: genuinely
distinct, or drift? Cross-check the repo's glossary/terminology doc — a term that contradicts or
is absent from it is the strongest finding (and a *gap* in the glossary is often the root cause
of the drift). Field-name drift for one datum across tiers (row → record → DTO → wire → UI). Idiom
drift for one operation (`assertX`/`requireX`/`checkX`/`ensureX`; `createX`/`makeX`/`buildX`).

**Starting points.** Grep the synonym sets; `codegraph_explore` to confirm two names are one
concept; read the terminology doc and diff the code's vocabulary against it.

**Structural fix.** Collapse each cluster to the canonical term (prefer the one matching the DB
table / the glossary); extend the glossary to *own* the domain so future drift has an authority to
check against.

## 12. Design-doc / process-artifact coupling in code

**Class.** Code whose comments are dense pointers into a mutable, non-authoritative design doc
(`§` section refs, `node XN` ids, `finding NN`, `rev N`) rather than self-explanatory prose — the
code can't be understood without the doc open and silently rots when the doc is renumbered.

**Hunt.** Quantify: comment-line ratio per file, count of `§`/`node`/`finding`/`rev` refs. Sample
citations and check they still *resolve* in the cited doc (an orphan on day one is a confirmed
finding). Whether an authoritative doc (spec) cites a non-authoritative one (research) as if
normative — an authority-ladder violation. Split load-bearing rationale (a real invariant/ordering
the reader needs) from pure provenance noise (`// node R6`). Estimate the pattern's contribution to
diff size.

**Starting points.** Grep `§`, `node [A-Z][0-9]`, `finding`, `rev `; count comment lines; open the
cited doc to verify a sample of refs.

**Structural fix.** Inline the load-bearing rationale self-containedly; delete provenance noise
(it belongs in commit messages); promote genuinely normative rules up the authority ladder into
spec/decisions.

## 13. Config, boot & magic values

**Class.** Magic strings/numbers; config knobs read nowhere or validated decoratively; boot
sequencing that couples unrelated concerns; the same constant hardcoded in several places.

**Hunt.** Repeated literal hosts/limits/timeouts (candidates for one named constant / injected
config). Config schemas that validate at import but not boot, or coerce a value that's then
discarded. Boot-order coupling. A security-relevant constant (an allow-listed host) living inline
instead of injected — flag for the owner to re-confirm it's a deliberate product decision, even
when the placement is architecturally fine.

**Starting points.** Grep repeated literals; read the config loader and boot module.

**Structural fix.** One named/injected source per value; validate-at-boot with fail-closed refusal;
assert config invariants at construction.
