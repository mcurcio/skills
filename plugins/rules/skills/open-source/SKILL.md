---
name: open-source
description: How the owner's public open-source repos are built - a standalone, reusable project anyone can install and customize, never a copy of the owner's own installation. Use when creating a public repo or one meant to go public ("open source this", "make this repo public", "publish it on GitHub"), extracting code into a reusable package or library, removing the owner's hostnames, paths or names before publishing, and when designing, coding, documenting, pushing, or opening PRs, issues or comments on a public repo; also when deciding what belongs in the generic project versus the owner's private installation. Not for private-repo work. Release mechanics (versions, tags) are releases:semantic-release.
---

# Open-source projects

The rule (a public repo holds nothing about the owner's setup) is in `rules:global` §Delivery;
this page gives the owner's words and how to build a project that keeps it. It covers every
public repo the owner builds.

Owner's rule (stated 2026-11-15, called a rule 2026-11-16, a private project): "Public repos
cannot contain any information about my specific setup and must be presented as if they are a
standalone, reusable open source project."

Owner's guidance (2026-11-17, a private project): "The goal is to build truly generic solutions
that work for many people and installation topologies rather than 'just me'", and "when i build
a public repo, i have an expectation of customization and flexibility".

## 1. The project is the product; the owner's setup is one installation of it

| Belongs in the public project | Belongs in the owner's private installation |
|---|---|
| The generic code, its interfaces and extension points | The owner's values: hostnames, domains, addresses, paths, accounts, names of the owner's machines, agents and services |
| Configuration options with working defaults | The config file or manifests that set those options for the owner |
| Generic docs, a quickstart and examples with placeholders | Deployment wiring, and design records that name the owner's setup |
| Tests that use fake data | Anything that only makes sense on the owner's machines |

The installation (a private repo, or the owner's own config) consumes the project and configures
it: a released artifact (package, image, chart), or, for a project that ships none, the repo
itself at a release tag (as a Claude Code plugin marketplace is consumed from git). The project
never imports, names or assumes the installation.

Author identity is not setup: the owner's public name, GitHub handle and public email stay in
the LICENSE, the package metadata and the repo's URLs.

## 2. Build for many users and topologies

- **Every environment value is configuration.** No absolute path, hostname, domain, repo name,
  account or cluster layout in code: each is a config key, CLI flag or environment variable
  with a default that works out of the box, or a clear error where no default can. Document
  every option.
- **Right-size the extension points** (`rules:global`: right-size). A value that varies is
  configuration. Add a pluggable interface (adapter, provider, hook) only when a second real
  implementation exists or a user asks for one.
- **Prefer standards to one vendor.** Speak standard protocols and formats (OIDC, not one
  identity provider's API), so another provider works through configuration alone.
- **Ask "could a stranger with a different setup use this?"** of every design choice. If not,
  the owner's value moves into configuration.

## 3. Writing it

- Examples use placeholders: `example.com` and the `.example` and `.test` names (RFC 2606);
  `192.0.2.0/24`, `198.51.100.0/24` and `203.0.113.0/24` (RFC 5737); `2001:db8::/32`
  (RFC 3849); `alice`; `/path/to/...`. A typical private range (`192.168.1.0/24`, `10.0.0.0/24`)
  reads as someone's real LAN.
- README: what it is, a generic quickstart, a configuration reference, how to extend. A LICENSE
  and CONTRIBUTING. Release mechanics are in `releases:semantic-release`.
- Commits, branch names, PR and issue text, and release notes are public too: describe the change
  generically, never "for my cluster" or a private issue-tracker id. Cite a private project as "a
  private project".

## 4. Making a repo public

Switching a private repo to public publishes its whole history and also its issues, PRs (their
`refs/pull/*` keep every PR's commits, even after a history rewrite), Actions logs, releases and
wiki. Default to a fresh public repo whose one initial commit is the cleaned tree. A secret that
was ever committed is leaked: rotate it; a rewrite does not un-leak it.

## 5. Before every push

Read the diff, the commit messages, and the PR or issue text for:

- the owner's domains, hostnames, IP addresses, machine names, local paths, private repo or
  issue names, agent names, personal data;
- secrets: `.env` files, tokens and keys, in the tree and in history;
- CI config: self-hosted runner labels, private registries, secret names;
- issue and PR templates, and CODEOWNERS;
- a shipped sample config copied from the owner's own;
- recorded fixtures, snapshots and screenshots;
- agent files (`CLAUDE.md`, `AGENTS.md`, `.claude/`) with notes about the owner's environment.

A setup value in code or docs moves into the installation as configuration; one in a commit
message or PR text is reworded, not turned into configuration.

## 6. Keep it light

The owner rejected a publish gate with a staging repo and a deny-list scanner (2026-11-17, a
private project): "i dont like the second repo idea. this is a lot of overhead and its stressing
me out", and "this whole thing is a nasty detour. drop the whole concept." He asked instead for
"something like an 'open source' skill that lays out the ideas that i espoused".

So the by-hand read in §5 is the check: no list knows every name. Add only free tooling that
already exists, such as GitHub secret scanning with push protection, never a new gate, repo or
scanner (`rules:global`: right-size, prior art first).
