---
name: pages
description: How every page or report for the owner is presented - an Artifact page, a design gate, a review report, a status or results page, a dashboard. Decision or result first, options as comparison tables, every term linked to its definition with a one-line meaning, settled answers apart from open questions, what changed since his last look, folded reference detail, and an impeccable design pass before publishing. Load before writing or revising any page or report the owner will read.
---

# Pages for the owner

The owner, 2026-11-01: "when agents give me artifacts today, they are prose-heavy and difficult
to parse. a good designer would be useful in presenting those artifacts in a thoughtful
manner"; and "I would hope that any jargon and/or terms link out to definitions elsewhere,
including prior discussions or design docs or existing code interfaces, etc." These rules hold
for every page an agent makes for him. A design gate also follows `workflow:design-doc` (the
ladder and the canonical shape); a review report also follows `workflow:antipattern-review` §4.
The words themselves follow `rules:global` §The owner's language.

## 1. The first screen carries the point

- One sentence on what the page is and what he is asked, or what happened.
- Then the summary that would let him act without scrolling: for a page with open questions, a table of
  each open question with the recommended answer and its cost, each row linking to its
  question; for a report, the result and its user impact.
- Everything else follows, in the order he needs it.

## 2. Options are comparison tables

- One table per question: a row per option with **gives**, **costs** and **what you'd see**
  (a concrete result in his terms: the status line printed, the banner shown, what happens on
  the device or cluster). The recommended row is marked; the whole row selects the option.
- The question's reason is one sentence above the table. A cell is a phrase, not a paragraph.

## 3. Settled apart from open

- An earlier answer of his is shown as settled: his words, the date, a link to where they are
  recorded. Only open questions take input.
- A revision opens with **What changed since your last look**: a short list of what moved,
  each linking to its section. He does not re-read a page to find the difference.

## 4. Every term links to its definition

- Each term of art, project term or piece of jargon is a link to where it is defined, best
  first: his own words (the project's notes doc), the design doc section, the code (a public
  interface, pinned to a commit with a line anchor), the tool's or library's own docs.
- Each link carries a one-line meaning shown on hover and keyboard focus. On a phone the first
  tap shows the meaning and the second follows the link.
- A term with no home anywhere goes in the page's terms table (meaning, why it is needed),
  which is itself linked from the term.
- Before publishing, check that every linked page loads.

## 5. Short, with the depth folded away

- The visible page holds what he needs to decide or act, at about 600 words. Reference detail
  for reviewers (contracts, wire types, full requirement lists, plans) sits in one folded
  section.
- A reason is one sentence. A paragraph over three sentences becomes a table, a list or a
  diagram.
- Structure carries information: no labels above headings, no section numbers unless the
  order matters, no cards around every block.

## 6. A designer's pass before publishing

The `impeccable` skill (pbakaus/impeccable, required by this plugin) is that designer. Before a
page goes to him:

1. Run its `distill`, `clarify` and `layout` passes on the page, and read its craft floor.
2. Run its detector over the file (`impeccable detect --json <file>`) and fix what it finds.
3. Check the page once at phone width and in both themes where the session can render it.

## Pre-publish checklist

- The first screen alone tells him what is asked or what happened.
- Every question is a comparison table with gives, costs and what you'd see.
- His earlier answers are shown as settled, with his words; a revision says what changed.
- Every term links to its definition and shows a one-line meaning; every link loads.
- The visible page is about 600 words or less; reference detail is folded.
- The impeccable pass and its detector ran, and their findings are fixed.
