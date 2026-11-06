---
name: global
description: The owner's global engineering rules (design philosophy, the owner's language, delivery, always-on habits). Injected into every main session by this plugin's SessionStart hook; agents preload it. Read it whenever a rule's exact wording matters.
---
# Global instructions (every agent, every repo)

"The owner": the maintainer of the projects these rules serve, Matt (GitHub mcurcio). In a
contributor's session, "ask the owner" means raise it with the maintainer on the PR or issue.
Point to another file by its plain path, never an `@` import (it loads the whole file).

**Precedence.** The owner's most recent statement wins, and one recorded in a single project
applies only there. Where a repo file, agent body or memory contradicts this file without quoting
the owner, this file wins (undated rules here: 2026-10-08). Report any contradiction.

## Design philosophy
- **Good architecture simplifies implementation and maintenance:** decide and review the shape before encoding it.
- **Make the failure class impossible**, don't patch the instance. A convention someone must
  remember is not a fix.
- **Guarantees, strongest first:** compile-time > construction-time > boot-time > test >
  convention > comment.
- **Depend on abstractions across boundaries**, never on concrete classes. Keep domain logic free
  of I/O: effects live in adapters at the edges.
- **Coordinate by events, never timers** (owner, 2026-10-24: "It's all event driven"). A timer,
  poll or start time guessed ahead standing in for an event is a race.
- **One concept, one domain.** Never derive one concept's state from another's signals (the owner
  rejected judging node health from missed "ready" events, 2026-10-24: health is its own
  process). Each domain has its own judge.
- **A shared domain has one model.** Every component taking part in one process runs one shared
  definition of it (one state machine, one contract), never a flow per component.
- **Trace every invariant to the owner before encoding it.** A rule in a requirements doc with
  no owner quote is an assumption: verify it before a design rests on it or code enforces it
  (owner, 2026-10-23; the case is in `rules:owner-design`).
- **DRY and SOLID.** The owner: "I value DRY and SOLID much more than YAGNI" (a private repo,
  2026-07-15); "DRY and SOLID are always important"
  (2026-10-08).
  Single-responsibility modules behind interfaces, and one authoritative home for each rule,
  value or policy, in code and docs alike. YAGNI may remove unused features and speculative
  surface; it never justifies duplicated logic, a merged responsibility, or failing a
  well-factored module because it has one consumer today. Values that must vary independently
  are not duplicates.
- **Prior art first.** Name the established pattern, mature tool or framework idiom (from its
  official docs) before designing a mechanism, and justify any bespoke one against it. A repo doc
  calling a non-idiomatic pattern "necessary" is a claim to test, not proof.
- **Right-size.** Start from the smallest design that meets
  the owner's literal asks and justify every addition; delete unrequested machinery rather than
  harden it. Never remove good code just to save lines.
- **One source of truth per piece of state.** A cache, in memory or on disk, never wins over its
  source; correctness and health hold with the cache empty.
- **Every persisted record carries audit fields:** when it was created and by whom, and when it
  was last changed and by whom, as its own columns written by the persistence layer (next rule), never
  derived from other data (permissions, history, logs). An append-only event table meets this
  through its rows (one event, its actor and time). Owner, 2026-10-24.
- **Persistence lives behind repositories** (domain-driven design's layered architecture and
  Repository pattern). The domain layer never touches the database: it asks a repository,
  one per aggregate, through an interface. Every database operation sits in the
  infrastructure layer's repositories, built on an ORM, ODM or query-builder layer.
  Cross-cutting persistence concerns (soft delete, audit-field stamping, tenancy filters) are
  applied once in that layer by an established library or the ORM's own feature (global
  query filters, scopes, soft-delete plugins), never written by hand in each query. Soft delete is valid where it fits. Owner, 2026-10-24 (quoted in `rules:owner-design`).
- **State costs, don't sell:** say what a design gives up, leaves uncovered and defers.
- **The spec is the source of truth.** Code that disagrees has a bug, unless the work proved the
  spec wrong; report that as a finding, never diverge silently.
- **No backwards compatibility** unless the owner asks: no default-to-old flags or dual paths. The
  PR is the gate; `git revert` is the undo.
- **The Architects rule** (owner, 2026-10-08): "architects can have the full code, but
  their job is to bias towards best practices and design patterns and they should NOT over-index
  on code that is proposed". Read the code for its constraints and the cost of change; it is
  evidence, not a template. Design toward best practice and established design patterns, and
  argue for any choice to generalize what is there.

## The owner's language
- Anything for the owner is plain language in the owner's terms: check what each named
  artifact is before naming it, and translate jargon and acronyms.
- Every noun is a defined project term or sits in a new-terms table (definition, why needed, which
  existing term it could be). Keep existing names; integration concepts stay at the consumer
  edge; map a new owner word to an existing term out loud and ask to confirm.
- No new infrastructure where an existing transport carries it; contracts are plain named methods,
  one per question, never a generic `apply(change)`.
- A requirement credited to the owner quotes those words, dated, with its source; never present an
  inference, a default or a design choice as the owner's. Restate an answer in the owner's words before building
  on it: a stated principle steers how, it does not widen scope.
- Every question to the owner, chat included, first gives the background it needs, visually where
  possible (drawn, never Mermaid source), and is labelled "general guidance" or "absolute
  requirement".
- Only two things make a requirement (owner, 2026-11-06): a question asked as an absolute
  requirement and answered yes, or a statement the owner calls a rule. All else said or picked is
  revisable guidance; keep that tag in handoffs.
- Never assume an unstated expensive constraint (keep data, stay compatible, can't
  recreate) or a detail the owner can supply in a minute (a reference screenshot): ask one plain question.

## Delivery
- Work lands through a PR the owner reviews and merges: never merge it yourself, never push to
  main. Live systems change only through the repo's PR-driven deploy unless the owner asks for one.
- Commits follow Conventional Commits. Releases come only from the repo's automated flow after
  merge: never hand-tag, hand-edit a version or add a pre-merge release path. That flow is
  semantic-release, releasing automatically when a PR merges, never release-please (owner,
  2026-11-01, quoted in `rules:owner-delivery`); Lerna only where a monorepo versions packages independently.
- **CI is the full gate** where the repo's CI runs its full suite on every PR (read its CI
  config): locally run the changed packages' tests, typecheck and lint, and let CI judge the
  pushed branch; run the full gate locally only when CI cannot (spending limit, quota). Mutation
  probes and tiers the repo says CI skips stay local; without such CI, verifiers run every gate
  the repo lists. Owner, 2026-10-08 (quoted in `rules:owner-delivery`).
- Tests prove behaviour through the real artifact, not its structure; verification checks a
  capability, not a status that can stay green while the capability is dead. Keep tests and each
  CI leg fast: a slow tier is a cost to argue for, not a default.
- Run a repo's tools under its pinned runtime (`.nvmrc`, the lockfile), never the shell's default.

## Always
- Report where the spec, plan or brief is wrong; that is a finding.
- **Record learnings as skills.** Owner, 2026-10-09 (a private project): "I want to start making a
  (global) habit of recording learnings as skills". How to operate a system you just learned
  goes in a skill: in the repo's `.claude/skills/` when it is
  about that repo's systems, in your user-level skills folder when it holds across projects. Update an
  existing skill over adding a near-duplicate. Facts about the owner or a project's
  state stay in memory files.
- Secrets come from the project's secret store at runtime. Never put a real one in
  source, fixtures, logs or evidence, and never type one into a UI field: hand that to the user.
- A failure called "pre-existing" needs its stack trace, a check that the failing path runs
  through no file the change touched, and an A/B without the change when that is cheap.
- Take an exit status from the command itself, never through a pipe: run it
  unpiped or read its pipe status.
- Undo your own edit by reversing it; never `git checkout`, `restore`, `stash` or `reset` a file
  that holds uncommitted work.
- List every check you skipped or could not run as NOT RUN; never claim a result you did not see.
- Pin the model of any agent or workflow step you define; `inherit` only when the parent's model
  is pinned; never a moving alias.
- The chat message is the answer: never hide a fact, finding, result or question in a side panel
  or a button the message lacks. Close every loop: a "checking X" ends with what X turned out to be.
