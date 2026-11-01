---
name: grammar-soundness
description: Traps and working methods for proving a language grammar unambiguous and checking parsers against it — which parser generators actually check ambiguity, which lexers are longest-match, and how to make the checks bite. Use when choosing a parser generator, writing or checking a grammar (EBNF, ANTLR .g4, tree-sitter, Lezer, Lark, REx, Bison), or claiming a grammar is "proven" sound.
---

# Grammar soundness: what the tools really check

Learned on the villanelle / @rasl/config grammar (2026-10-21/22; mcurcio/rasl#2, mcurcio/villanelle).

## Which tool proves "unambiguous"

| Tool | Refuses an ambiguous grammar? | Lexer |
|---|---|---|
| Bison (`%expect 0`) | yes (LALR(1) conflicts, exit 1) | none; feed it tokens |
| REx (W3C EBNF) | yes (`-lalr 1`; also reports token ties) | per-state longest match |
| Lark `strict=True` | yes, but silently skips the collision check for terminals with lookahead | first match, NOT longest |
| tree-sitter | yes outside repeats; silently resolves ambiguity inside `repeat`; `conflicts:` / `prec` silence it | per-state, context-aware |
| Lezer | yes, but `@precedence` is rule order, not longest match | rule order |
| ANTLR4 / antlr-ng | **no**: builds an ambiguous grammar with exit 0 | longest match, then rule order |
| syntax-cli 0.1.27 | its LL(1) FOLLOW sets are wrong; don't trust it | — |

- A grammar with no LR(1)/LALR(1) conflicts is unambiguous; ambiguity in general is undecidable,
  so "ANTLR checks ambiguity" is never true statically.
- Working recipe for ANTLR4: mechanically translate the `.g4` parser rules to Bison
  (EBNF operators to fresh rules) with `%expect 0`, and REFUSE actions, predicates, lexer
  commands and modes (they can hide a conflict). Check token kinds pairwise-disjoint with
  `interegular` on regexes built from the lexer rules. With disjoint kinds, rule-order
  tie-breaks never decide.

## Make every check bite

- Keep planted bad grammars (duplicate alternative, optional separator, optional gap,
  forbidden feature) and require each to FAIL in CI. Rebuild them from the current grammar;
  stale planted files can fail for an unrelated syntax error and look like a catch.
- Testing two parsers that share a component (same lexer, same EBNF reader) cannot vouch for
  that component.
- "Tested on N generated inputs" is evidence, not proof; say which. Put NUL, control
  characters, lone surrogates, BOM and astral characters in the corpus: a REx-generated parser
  treated NUL as end of input; web-tree-sitter accepted lone surrogates.

## Lossless CST with a generator

- Make whitespace, comments and newlines ordinary grammar tokens (no hidden channel, no
  `skip`, tree-sitter `extras: []`) when spacing rules matter or the tree must round-trip.
- Write repetition as loops, not right recursion: ANTLR's Python runtime hit RecursionError at
  ~300 values on a line in the recursive form.
- ANTLR's default error recovery invents `<missing '}'>` tokens; a custom
  `DefaultErrorStrategy` (~95 lines per language) gives statement-level recovery.
- tree-sitter's TS (wasm) and Python runtimes give different error positions unless the core
  version AND the input encoding (UTF-16) match; its first-error offsets often point too early.

## Shell trap

In zsh (macOS's default shell), `${PIPESTATUS[0]}` is empty, so a check loop can report every exit
as 0. Run exit-code-sensitive checks under `bash -c` or in a `#!/usr/bin/env bash` script.
