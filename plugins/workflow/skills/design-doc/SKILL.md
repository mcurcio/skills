---
name: design-doc
description: Produce the ONE owner-gate design briefing — scoped to the NEXT layer of the design ladder only (domain → system → service → module → interfaces → implementation), frame-level, at most 3 questions, visual, separating hard Requirements from revisable design choices, showing at every layer how the proposal fits the canonical shape (the domain model and its changes, and the design patterns used), listing every new term, and asking each question beside the section it concerns, with its background and the kind of answer it wants. Load before writing any design artifact for a user gate, whenever the owner wants options to pick from, before briefing any design/review agent, while the owner is refining a design in chat, and whenever asked to consolidate design docs. Publishing mechanics (Artifact page, saved answers, PR record) are in reference/publishing.md.
---

# design-doc

The deliverable of a design gate is one **briefing** the owner can review in a
single sitting. It covers **one layer** of the architecture, and it is visual:
the diagrams, tables and interface sketches carry the design, and prose only
connects them. This file is the drafting craft; how any page for the owner is presented
(first screen, comparison tables, linked terms, the design pass) is `rules:pages`, and whoever
publishes the briefing (usually the main session) also reads `reference/publishing.md`.

## Rule 1: architect only the next layer

The design ladder has six layers (owner, 2026-11-01, picked from offered options: "Six, domain
as its own rung"). Every gate covers the layer directly below what is already agreed, and
nothing deeper. Name the layer before any design agent spawns, put it in every architect's and
reviewer's brief, and show it on the briefing's header. A small project may skip a layer
(service, most often) and says so on the page.

| Layer | When | What the owner weighs in on | The page leads with |
|---|---|---|---|
| **Domain** | New project, new subsystem, or a change to what the system is about | Bounded contexts, the concepts each owns, their states and invariants, the language, what is NOT each context's job | Context map and domain model, new-terms table |
| **System** | Once the domain is agreed | The system's parts and their public interfaces (API contracts); for a new project, technology choices and deployment topology | Component picture, interface sketches in TypeScript |
| **Service** | A system with more than one running service | Which services exist, what crosses between them (events, calls), who calls whom, who owns which data | Service map, sequence diagrams of the key flows |
| **Module** | Designing a specific module or cross-module change | Module boundaries, contracts (what each takes, gives, never does), data flow, who owns which state | Module map, contract table, data-flow table |
| **Interfaces** | A module's public surface | Signatures, error unions, what each caller is injected with, invariants as doc comments | The signatures, each linked to the code it changes |
| **Implementation** | A specific feature inside an agreed module | Algorithm choices, data structures, edge-case behaviour, the slices and the test that shows each working | Algorithm comparison, examples table, slice list |

An implementation-layer gate is often a conversation, not a page.

## Rule 1b: every layer shows the canonical shape

Owner, 2026-11-01: "I want any design to look through the lens of 'how does this proposal fit
into the canonical shape?'", meaning both the project's domain model and the established
pattern, "and: 1) what changes to the domain does this proposal impose 2) design patterns that
will be used, because design patterns are encouraged". So every briefing, at every layer, has a
**Canonical shape** section with two parts:

- **Domain:** the domain concepts this proposal touches, adds or changes, each linked to the
  agreed domain model, and the changes it imposes on that model. Below the domain layer, a
  change to the agreed model is a question for the owner, never a quiet edit.
- **Patterns:** each design pattern the proposal uses, named, linked to its canonical source
  (the pattern's reference, or the framework's own docs) and placed where it is used; any
  departure from the established pattern for this problem, with the reason
  (`rules:global` §Design philosophy, prior art first).

**A gate is frame-level (owner, 2026-09-25).** It holds the requirements, one component picture
with responsibilities, the 1-3 key flows, and a hierarchical bead outline (epic → logical
units). It fits in 1-2 pages. Unit internals are explicitly "decided in that unit", never listed
as open rows. Detailed up-front design locks in choices before implementation reveals the real
scope, and a long multi-question page cannot be reviewed by a human.

**Domain boundaries come before any mechanism (owner, 2026-10-24):** "Instead of going straight to
the technical solution, you must first understand the domain boundaries." On 2026-10-23/24 five
drafts of one design went straight to watermarks, transports, timers and barriers while the
bounded contexts (what a standalone Player is versus one directed by Central; preparation as a
continuous loop, not a one-time step) were never drawn, and the owner had to ask
questions to expose the assumptions. So a domain-layer pass opens with the context map: each
bounded context, what it owns, its language, how contexts relate, and which modes each runs in.
Briefs to architects carry the problem and the owner's words, never a list of mechanisms to
include; a reviewer treats any protocol, timing or transport detail at this layer as a finding.

**At the system layer, show only the domain model and the interfaces (owner, 2026-10-03):**
"At the system architecture layer we are only trying to solve domain modeling and interfaces."
Since 2026-11-01 the domain model is agreed on its own layer first, and the system page carries
it as settled. Show the types, the interface methods, what each caller is injected with, the error union, and
invariants as doc comments. Internals (locks, caches, jobs, storage, lease arithmetic) belong
to the code architects: park them under "for the code architects" in working state.

**Out of scope for any briefing:** everything from the layers below it, such as
`file:line` facts, acceptance-criterion IDs, failure-mode tables, state-machine
thresholds, per-bead plans, mutation probes and review dispositions. Deeper
detail is designed later, at its own gate. Designing all layers at once is the
failure this rule exists to prevent: an hour of work producing a document too
detailed to review.

Working state (briefs, reviewer findings, dispositions, deeper-layer notes the
reviewers raised) lives in the scratchpad or on disk under `.claude/`. It never
ships beside the briefing, and it never gets folded into it.

## Rule 2: requirements are not design choices

Keep two kinds of statement apart, visibly and in every agent brief:

| | **Requirements** | **Design choices** |
|---|---|---|
| What | Hard rules the design must satisfy: owner requirements, documented requirements, external constraints | How this design meets the requirements: shapes, mechanisms, options picked among alternatives |
| Nature | Binding until the owner changes them | Transient and subjective. Revisable whenever a better option appears |
| Where they come from | Only the two sources under this table (2026-11-06). A requirement document's rule that quotes neither is an assumption to verify with the owner, never binding by itself (2026-10-23) | The architect's recommendation, adjusted by the owner's answers |
| On the page | Their own **Requirements** section, as a numbered list (R1, R2, …) with source tags | In the section that describes them, as the current choice with its alternatives |

- **What creates a requirement** (owner, 2026-11-06, answering yes to this wording, addressed to
  the owner): "Only two things create a requirement: a question asked as an absolute requirement and
  answered yes, or a statement where you say it is a rule. Everything else you say, and every
  option you pick, is guidance." Guidance records the current preferred choice and does not freeze
  the design; later evidence can reopen it. A firm statement that is not called a rule gets one
  "is that a rule?" before it binds.
- **A global rule is background on a design page** (owner, 2026-11-06, asked whether one counts
  as a requirement there: "its background"). Agents still follow it. The page cites it as guidance,
  and it joins the Requirements section only if the owner says so for that design.
- **Every statement keeps its source through every handoff:** requirement (the owner's quote, dated),
  guidance (the owner's quote, dated) or proposed (an agent's option or claim the owner has not answered). A
  picked option becomes guidance, recorded as "picked B, worded by the agent"; unpicked options
  are dropped. Briefs, working state and later pages keep the tag.
- **"Decision" means a specification rule the owner explicitly stated as one** (owner,
  2026-11-05: "'Decisions' is not a totally banned word; but we must encode the
  nuance between my general statements and questions vs specification rules that
  I explicitly state as such"). Never call the owner's answers or general statements
  "decisions", and never call them "rulings". Use "questions", "answers" and
  "current choice".
- **A design that would break a requirement** is not a design choice. Raise it
  as a question in the Requirements section ("change R6?"), with the reason.
  Never flag it as a departure buried inside a choice.
- **The design's own rules** (the at-most-three invariants that make the shape
  hold) are design choices. Label them "design rules" so they are never
  mistaken for requirements.

## Rule 3: make it visual

- **Shape:** a clean top-to-bottom walkthrough of short sections. Each section
  is a heading, at most two sentences, then a visual.
- **Visuals:**
  - Drawn diagrams: flowcharts for structure, sequence diagrams for flows, state diagrams only
    when the state machine *is* this layer's subject. The owner sees a rendered picture, never Mermaid
    source (owner, 2026-11-06: "flowcharts written in mermaid are less useful than flowcharts
    rendered as an image").
  - Tables for requirements, contracts, data flow and comparisons.
  - Code blocks for interface sketches (the public interfaces at the system
    layer; signatures at the interfaces layer).
- **TypeScript sketches are written for reading** (owner, 2026-10-03): multiline fenced
  blocks, one member or field per line, inline `//` comments on enum members and fields,
  blank-line or comment separators between groups, never an enum or union packed onto one
  line. Readable code beats a line cap; prose only connects the code blocks.
- **No walls of text.** A paragraph longer than three sentences is a sign the
  thing needs a table or a diagram instead.
- **Questions sit where they belong.** Each question card goes directly under
  the section that explains the thing it asks about: the redirect question
  under the flow diagram, the packaging question under the module map, the
  scope question under "what happens next". Never collect questions at the
  bottom.
  - Each question opens with one plain line saying what is being asked, then a fold-out of the
    background that question needs, at its technical level: a diagram, table or image first (owner,
    2026-11-06: "visuals are more powerful than words"), covering what the thing is, when it
    comes up and what the answer changes. The owner can answer from the page without opening code. If
    that background will not fit, the question is too deep: the architect makes the call and
    shows it as a recommendation.
  - Each question says what it asks for, in words and in its wording. **General guidance:**
    "which way should this lean?". **Absolute requirement:** "must this always hold, even when
    it costs X?", with the exact sentence that would bind and what it rules out. A line under
    the options says how the answer will be used.
  - Each question is a comparison table (`rules:pages` §2): the current choice
    (recommended) and each alternative, with what it gives, costs and what the owner would see. A
    guidance question with no real options may ask for the owner's direction in a note instead.
  - A "the rest of this section is recommended as shown" line under a section
    lists its smaller choices, so any of them can be reopened.

## Rule 4: the owner's language

Plain words, known or declared nouns, existing names, no invented machinery, the owner's requirements
in the owner's words: the rules are `rules:global` §The owner's language; the reasons and the
craft are the `rules:owner-conversation` skill.

## Briefing structure

Sections in this order. Drop a section if it is empty. Questions appear inside
sections, never as a section of their own.

1. **Header:** title, status, a **where-am-I strip** (all six layers, this one
   highlighted, each agreed layer above linked to its record), one line saying
   what the owner is being asked, and the open-questions table (`rules:pages` §1).
   On a revision, **What changed since your last look** follows the header.
2. **Today:** one diagram of what is broken or missing, with the failure points
   marked.
3. **Requirements:** the hard rules, numbered, each with its source (owner,
   requirement doc, external constraint). Any proposed change to a requirement
   appears here as a question. The **New terms** table follows, if any.
4. **The proposed shape:** one diagram for this layer (context map, component picture, service map,
   module map or interface sketch), with its questions beneath it.
5. **Canonical shape:** the domain part and the patterns part (Rule 1b).
6. **Design rules:** at most three invariants, as cards, labelled as design
   choices. If the layer can't be stated as three rules, it isn't designed yet.
7. **The layer's core tables** (Rule 1, "The page leads with"), each followed by its
   questions.
8. **Costs and deferrals:** what it costs (at most 5 bullets), deferred (later),
   not planned (non-goals).
9. **What happens next:** for a delivery gate, the tracer bullet and the hierarchical bead
   outline (epic → logical units); for a design that goes deeper, the next layer's gate. The
   scope question goes here.

Keep a one-line history in the footer, not a section.

## Question volume is a signal

- **At most 3 questions per gate** (owner, 2026-09-25: weighing ~15 concepts at once is
  "unrealistic"). Everything else is deferred to the unit that owns it, not listed.
- More usually means the gate is mixing layers, or the architecture is wrong. Stop and
  re-cut before presenting.
- Each question is something only the owner can answer, not a mechanism question the design
  should have answered.

## Producing it from the pipeline

- **Brief every agent with the layer, the requirements list, the owner's guidance and what is only
  proposed, kept apart,** plus a length cap and the question cap. Architects design this layer
  only. Name the Architects rule; `rules:global` already delivers its text.
- **Reviewers attack the model, not the plan:** does the layer satisfy every requirement, is
  the domain cut right (concepts, ownership, invariants, what is not this context's job), and
  are its choices sound? They do not propose mechanisms. A reviewer finding that a requirement
  itself is wrong is raised as a requirement question, never silently designed around.
- **Park deeper findings.** Findings about deeper layers or mechanisms go to a parked list in
  working state ("concerns for unit X", "for the code architects"). They do not grow the
  briefing.
- **Many findings mean the model is wrong.** Go back to the domain model and fix the cut there.
  Never fold findings in as mechanisms: that is how pages grew 79 → 97 → 134 KB over two rounds
  and put work in a context that was not its domain.
- **A revision is the same length or shorter.** After the answers settle, run a separate
  condense pass before republishing: keep the full design in working state and cut the page back
  to its layer's altitude (guide: ≤70 KB, about 20,000 px tall at 400 px wide).
- **Prefer drafting a frame inline** in the main loop over a large design workflow.
- **Write it once, at the synthesis step, after the layer survives review.**
  A revision republishes the same artifact, and a review round becomes one
  history line.
- **Consolidating an existing sprawl:**
  1. Identify which layer is actually under review.
  2. Separate the requirements from the choices.
  3. Build the briefing for that layer, with questions placed by section.
  4. Move deeper detail to working state as input for later gates.
  5. Delete the superseded files in the same commit.

While the owner refines a design in chat, the discussion runs on an Artifact page the owner answers on
(`workflow:orchestrator` §Owner gates); subagents return the content and the main session
publishes it. Publishing, saved answers and the durable PR record: `reference/publishing.md`.

## Pre-delivery checklist (drafting)

- The layer is named on the where-am-I strip, and nothing on the page belongs to a deeper layer.
- The canonical shape section names the domain changes imposed and the patterns used.
- Frame-level: 1-2 pages; unit internals deferred to their units; a bead outline at a
  delivery gate.
- Requirements and design choices are separate sections with separate labels.
  Every requirement has a source.
- Every noun is a known term or in the New terms table; no renamed existing terms.
- Every question sits under the section that explains it. None are collected
  at the bottom.
- Every question has one plain line, a fold-out of background led by a visual, and says whether it
  wants general guidance or an absolute requirement.
- Every requirement traces to a question answered yes or a statement the owner called a rule; nothing
  proposed or merely picked is listed as one.
- Every flowchart reaches the owner as a rendered picture.
- "Ruling" and "locked" never describe an owner answer or general statement; "decision" describes only a rule the owner explicitly stated as one.
- Every section leads with a visual. No paragraph longer than three sentences.
- The page passes the `rules:pages` checklist (linked terms, settled vs open, the design pass).
- TypeScript sketches are multiline, one member per line, commented.
- Three design rules or fewer, and they are true.
- At most 3 questions, each with the recommended option, alternatives and their
  costs, where it has options. A conflict with a requirement is a Requirements question.
- A revision is no longer than the page it replaces.
- Costs stated, never sold. Placeholder numbers say so.
- The owner could steer this layer, and the next phase could start, from this page alone.
