---
name: owner-design
description: Why the owner holds these design rules, and how the owner judges a design. Reasons and worked examples behind the design philosophy in the `rules:global` rules (architecture first, class not instance, DRY and SOLID over YAGNI, pure core, prior art, right-size, one source of truth, no backwards compatibility, the Architects rule), the owner's review lenses, and the review vocabulary (deep modules, deletion test, seams, altitude tree, rule of two). Use when designing a system or module, cutting boundaries, reviewing a design, or deciding whether to extract, share, keep or delete code.
---

# How the owner judges a design

The rules are in `rules:global` §Design philosophy and §The owner's language. This file
gives the reasons, the lenses and the examples; it never overrides a rule. Where it seems to,
the rule wins and the gap is a finding.

## Where the owner's rules come from

- **Good architecture simplifies implementation and maintenance.** "A good architecture can
  survive a bad engineer"; Code Complete and Fowler are the owner's touchstones. A diagram costs the owner a minute, a landed module a rewrite. In a
  private project, five modules were designed inside implementer prompts the owner never saw, and a
  digest design churned through three rounds until one question of the owner's collapsed it: "why would
  a sha digest leak into the [project's] server?" The owner wants to argue the shape before code, and
  welcomes redlines.
- **Decide small, challenge at once, implement fresh.** The design-first pipeline exists because a
  context that both decides and grades will anchor ("the long horizon is the enemy", the owner's original
  global CLAUDE.md).
- **Class, not instance.** The owner reads a fix that ripples across call sites as a coupling defect,
  not a big patch (in a private project: "I ALWAYS prefer a clean solution over a quick one").
  In another private project the owner stopped a one-line change mid-debug: the owner wanted "one coherent
  architectural decision over a sequence of small 'this should work' patches". A class fix there
  also closed a dormant third instance of the same gap before it fired. The first project's
  answer to "quick or clean?" was sequencing: what lands safely now, and what gets designed right.
- **Guarantees.** The owner wants principles encoded "as artifacts, orderings, forced questions, and
  mechanical impossibilities, never adjectives". One private project's safety model: the one
  function with the risky side effect accepts only a value whose constructor is private, so no
  other code can express the call.
- **Pure core, effects at the edges.** From a private project: "a safety or correctness guarantee
  that can't be tested is not a guarantee", so its safety logic sits in pure functions an
  assertion runner checks. photo-wall keeps domain and time logic free of GStreamer, GTK, Immich
  and hardware APIs; another private project keeps the domain pure over ports so the database
  driver can change.
- **DRY and SOLID.** "I value DRY and SOLID much more than YAGNI. Good design means modular
  components that Do One Thing Well." In a private project the owner kept a one-consumer library
  component after a reviewer failed it on a second-consumer rule. Another: "everything is simpler
  when code is properly compartmentalized." photo-wall's statement of it: reuse never means
  coupling independent modules or sharing mutable state. In a private project a value two
  components shared became one wired output, and a contract two of them needed became a general
  type in the shared library, not one app's type.
- **The Architects rule.** An architect handed file:line and "generalize the existing X"
  designed a boot recovery that marked a workload stopped and then adopted it back if its process
  was still alive: a race that existed only because the model guessed before it knew. The owner's shape
  was ground truth first. So inheriting the code's flaws is a finding; departing from the code is
  not.
- **Prior art.** "What are the design patterns and prior art that exist to solve this problem?
  Our goal is not to reinvent the wheel, but to build on the shoulders of giants." In photo-wall
  an architect given a menu of mechanisms built a bespoke leader election; four review rounds
  patched it before the owner named the standard answer (competing consumers on the Postgres
  queue already running). In a private project two agents agreed a framework workaround was
  "structurally necessary" until a third tested the framework's own idiom against its official
  docs. The owner
  leans to off-the-shelf tools and wants custom code justified with measurements.
- **Right-size, and its counterweight.** A small helper service grew to +3,130 lines over three
  review rounds; a ~300-line design met every ask ("a lot of code for something that sounds like
  a small problem"). A 2-bug fix grew into a 21-bead protocol redesign ("gone off the rails").
  The owner ranks by value per unit of new surface: a 15-file kit was "too many changes at once". But:
  "I don't want good code removed just to save lines in the diff." Cut dead, duplicated or
  reinvented code; keep construction-time guarantees, well-factored modules and tests that catch
  distinct behaviours.
- **No backwards compatibility.** The owner has said it many times. In a private project a fix landed
  behind a config flag that defaulted to the old behaviour, making the fix opt-in; the owner called that
  out as compatibility machinery. When a change breaks callers or tests built on the old
  behaviour, the owner wants them updated: the breakage surfacing is correct. A real ordering
  consequence goes to the owner as a scope question. rasl's working agreement says the same about
  aliases and shims.
- **Events, distinct domains, one shared model, self-sufficient nodes** (photo-wall,
  2026-10-23/24). The owner listed four bad proposals from one design round: "Using timers to prepare
  and schedule, rather than events"; "Trying to derive node health from 'ready' events even
  though health is clearly a distinct concept"; "Assuming different planning/preparation flows
  for central vs the nodes, even though it's part of a shared domain and all of the fleet is
  involved"; "Continuing to treat Central as the core system, when the Players should be
  designed as self-sufficient". The same round traced the photo locks and "a started cue is
  immutable" to agent-written founding docs the owner approved wholesale: "some implicit requirements
  were added along the way that i never approved", about 700 lines guarding "some integrity
  that doesn't actually matter".
- **Audit fields and repositories** (2026-10-24). On audit fields: "Having a 'who created this'
  is such a natural aspect of good database design that it should have been there from the
  start"; "This is a tenant of good database design." On persistence: "Soft delete is allowed,
  where appropriate. Don't preclude the technique."; "all db operations should be contained
  within data/repository/ORM/ODM layers backed by soft-delete libraries"; "This concept is
  related to good domain-driven-design practices where we must build clean layers of
  abstractions".
- **One source of truth.** A private project kept live sessions in a map that a read path
  preferred over the database row, so the API contradicted the database. photo-wall: "'healthy'
  does NOT equal 'everything is in the cache'"; a server that answered ready while a read of an
  evicted file failed broke a requirement. In-memory authority is also what blocks running two
  copies.

## Lenses

- **Prior art.** Name the problem class (work queue, idempotent job, lease and fencing token,
  content-addressed or read-through cache, outbox) and what mature systems do, then map it to
  what the repo already runs.
- **Simplicity.** Adversarial reviews attack whatever exists, so defending a big design breeds
  more code: the reason Right-size starts from the smallest design.
- **Policy leaks.** Under SOLID a caller talks to one decision point and cannot tell whether a
  mode is on. A private project expressed one mode switch three ways (conditional wiring, a flag
  branch, substitutable classes); its reported bug was small, yet the design half of the
  investigation found six real findings. An optional dependency whose absence meant
  three different things behind one `?:` is the recurring shape.

## Vocabulary (designs are built against it; reviews name it)

- **Deep module:** behaviour delivered per unit of interface complexity; the interface is the
  whole contract (signatures, invariants, error modes, performance class). A knob per behaviour
  makes a module shallow however much it hides.
- **Deletion test:** if the module were deleted and its body inlined at each call site, would
  total complexity fall? Merged responsibilities count as complexity, so a single-purpose module
  usually survives even with one caller.
- **Seam:** where a boundary is crossed or behaviour varies. The number of implementations is
  not the test.
- **Altitude tree** (where new code belongs; first yes wins): (1) intrinsic to this one feature
  in every environment: with the feature; (2) a pattern with its own single responsibility: a
  shared module named for the pattern, never the first app, differences arriving as parameters, never conditionals on the consumer, the
  first consumer migrated in the same change; (3) a mechanical wrapper over a platform primitive,
  shared type or constant: the lowest shared layer; (4) everything else is wiring: the
  composition root, which composes and does not compute.
- **Rule of two:** a value at one site lives there; at two or more sites it gets a name and a
  home.
