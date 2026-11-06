---
name: owner-conversation
description: How to talk with the owner and why. Reasons and craft behind the owner's-language rules in the `rules:global` rules and the owner-gate and reporting rules in the `workflow:orchestrator` policy - plain words, defined nouns, no new machinery or names, quoting the owner's requirements, asking instead of assuming, question volume, restating answers, Artifact pages while the owner refines and the notes doc, files the owner can open, user-impact reports. Use when writing a question, requirement, gate page or report for the owner, interrogating requirements, or deciding whether something needs the owner's answer.
---

# Talking with the owner

The rules are in `rules:global` §The owner's language, and for the main session the
`workflow:orchestrator` policy §Owner gates and §Reporting. How any page for the owner is presented is
`rules:pages`; the gate document's shape is the `workflow:design-doc` skill; the review report's shape is `workflow:antipattern-review` §4. This file gives the
reasons and the craft.

## Who the owner is in the conversation

The owner is the architect, steers through requirements and contracts, does not read
the code to follow a question, and judges the shape before the mechanism: one picture and a few
plain sentences first ("I need a 10,000 foot view of the solution before you inundate me with
highly technical questions"), detail only after the owner agrees the shape.

## Why the language rules exist

- **Plain words.** Jargon passed through from subagents cost whole round trips: "I don't know
  what inbox-scan means", "what client?". In a private project the owner asked for a set of technical
  choices without their acronyms, and with what each option does and costs.
  Craft: one plain sentence with the concrete scope, then the question, then the options with a
  recommendation and a cost.
- **Defined nouns.** A question in undefined terms cannot be answered, and answering it would
  ratify the term by accident. In a private project the owner asked what a proposed permission name
  meant to the project, and noted that a word taken from a partner system had no defined
  meaning in it: the partner's vocabulary was leaking into the core through design rounds. Audit
  nouns against the terminology on the main branch, not a branch under review, where new terms
  may have slipped in.
- **No new machinery, no new names.** On one private project's service interfaces: "[the
  service] emitting change events should be a normal event emitter (or flow through the
  [existing message hub]). Don't invent a new indexed-log infrastructure"; "why are [the
  permission records] being imported under the alias [a new name]?"; "What does 'apply' mean?";
  "there is no need for both [a single-check method] and [its batch twin]". New infrastructure
  is cost the problem did not ask for, a rename splits the shared vocabulary, a generic
  dispatcher hides what the contract does, and two methods for one question are one too many.
- **The owner's words, not your reading of them.** In a private project: the owner's explicit requirements are
  "the basic feature of all design docs", quoted with no interpretation. photo-wall: a design run
  listed its own assumed choices as the owner's answers, and a steer the owner gave was later filed as a
  requirement ("I never stated this as a requirement"). Another private project: "plugins don't
  own shared-schema tables" was built on as "plugins are stateless". Reconciling two of the owner's
  statements yourself is the same inference in another form.
- **Asking beats assuming.** In a private project an agent assumed a data store had to be
  preserved and built a migration, an abort gate, a rollback anchor and a snapshot step around
  it; the owner would have answered one question with "we can delete and recreate all of the
  resources". In another private project's UI work two guessed visuals cost full rounds: "you
  should have asked for reference material rather than guessing". Cheap to confirm, expensive to
  assume.

## Asking well

- **Every question carries its label, in chat too:** the words "general guidance" or "absolute
  requirement" beside the question, then what the owner's answer will be used for. In chat, the background
  is a line or two, or a small table, with no fold-out.
- **Volume is a signal.** Fifteen concepts on one page was "unrealistic"; about eight mechanism
  questions across three review rounds "fails the smell test: something about this architecture
  is wrong". Questions stay at product and architecture level; mechanism choices are the
  architect's to make and defend.
- **Answers are choices** (the wording rule is `workflow:design-doc` Rule 2). The owner objected to those picks
  being called rulings: a pick among options you framed is the owner's current preference, and the word
  freezes it.
- **Answers are guidance by default** (owner, 2026-11-06). The owner listed what keeps going wrong:
  "give me high level background information before asking a VERY technical question (for which
  i have no context to answer)", "ask me a question that i answer as _broad guidance_ but gets
  interpreted as a Declared Fact", "give me bullet point options that later get used as Declared
  Fact". The owner asked for questions "properly gauged and worded to reflect whether the question is
  looking for _general guidance_ as an answer or an _absolute requirement_". Another private
  project: "I don't understand the two questions. I don't understand the context around them and
  when they might occur". The rules and wording are in `workflow:design-doc`.
- **Visuals over words** (owner, 2026-11-06): "visuals are more powerful than words, so i prefer
  when background information is conveyed via diagrams and tables and images. flowcharts written
  in mermaid are less useful than flowcharts rendered as an image".
- **Why answers are restated.** In photo-wall a 2-bug fix grew over ten answers into a 30-hour
  protocol redesign ("gone off the rails"): every step was locally reasonable, and broad answers
  ("everywhere", "declarative") were read as new scope rather than as a steer on how.

## While the owner refines in chat

The owner discusses a design on a page that takes answers: "i prefer to have discussions via artifacts
rather than markdown documents because it is easier for you and i to collaborate" (photo-wall,
2026-10-06). The owner answers on the page, often from another device, so a page that cannot save
answers loses them ("I tried to answer in the artifact, but there's no way to save my answers").
A private project had the opposite answer three days earlier ("stop writing artifacts, because I
am not reading them"), after a long design page was republished from v8 to v14 while the owner settled
details in chat; on 2026-10-09 the owner kept the newer one everywhere ("keep the newer rules"). What
that episode still teaches: a page that grows every round goes unread, so each round condenses it.
The notes doc exists because context turns over: the owner's verbatim, dated words are what survives it.

## Reports the owner can act on

The owner decides fix-the-cause against patch-the-symptom from user impact, and "I dont like to patch
bugs without understanding why the bug exists". A list of 27 finding cards came back with "at
27 findings it sounds like some aspect of the design is wrong rather than 27 different bugs";
the next version, still listing every finding under its class, was "too long". So the depth goes
into the one or two root causes, and findings appear only as proof.

Pages the owner can open: "that markdown file is outside of the working tree, so i cant load it"
(photo-wall), and a review report sent from a hidden config folder never reached the owner (a
private project).
