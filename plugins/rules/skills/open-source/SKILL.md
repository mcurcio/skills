---
name: open-source
description: How the owner's public open-source repos are built - a standalone, reusable project anyone can install and customize, never a copy of the owner's own installation. Use when creating, designing, writing code or docs for, or pushing to a public repo (or one about to be made public), and when deciding what belongs in the project and what in the owner's private installation of it.
---

# Open-source projects

The rule (a public repo holds nothing about the owner's setup) is in `rules:global` §Delivery;
this page gives the owner's words and how to build a project that keeps it.

Owner's rule (2026-11-15, confirmed as a rule 2026-11-16, a private project): "Public repos
cannot contain any information about my specific setup and must be presented as if they are a
standalone, reusable open source project."

Owner's guidance (2026-11-17, a private project): "The goal is to build truly generic solutions
that work for many people and installation topologies rather than 'just me'", and "when i build
a public repo, i have an expectation of customization and flexibility".

## 1. The project is the product; the owner's setup is one installation of it

| Belongs in the public project | Belongs in the owner's private installation |
|---|---|
| The generic code, its interfaces and extension points | The owner's values: hostnames, domains, addresses, paths, accounts, names of the owner's machines, agents and services |
| Configuration options with sensible defaults | The config file or manifests that set those options for the owner |
| Generic docs, a quickstart and examples with placeholders | Deployment wiring, and design records that name the owner's setup |
| Tests that use fake data | Anything that only makes sense on the owner's machines |

The installation (a private repo, or the owner's own config) consumes the project's released
artifacts (package, image, chart) and configures them. The project never imports, names or
assumes the installation. The author's name and the repo's own URL are not setup: they stay in
the licence, the package metadata and the links.

## 2. Build for many users and topologies

- **No hardcoded environment.** No absolute path, hostname, repo name, cloud or identity
  provider, cluster layout or account in code. Read them from configuration, with defaults that
  work out of the box or fail with a clear message.
- **Customization is expected.** Every choice one deployment would make differently is an option:
  a config key, a CLI flag, an environment variable, or a pluggable interface (adapter, provider,
  hook) with a default implementation. Document every option.
- **Depend on standards, not on one stack.** Use standard protocols and interfaces (OIDC, not one
  identity provider; a storage interface, not one backend). The owner's stack is one adapter among
  others (`rules:global`: depend on abstractions across boundaries).
- **Ask "could a stranger with a different setup use this?"** of every design choice. If not, it
  is an option or an extension point, not a constant.

## 3. Writing it

- Examples use placeholders: `example.com` (RFC 2606), `192.0.2.0/24` (RFC 5737),
  `2001:db8::/32` (RFC 3849), `alice`, `/path/to/...`.
- README: what it is, a generic quickstart, a configuration reference, how to extend. A LICENSE
  and CONTRIBUTING. Releases by semantic-release (`releases:semantic-release`).
- Commits, branch names, PR and issue text, and release notes are public too: describe the change
  generically, never "for my cluster" or a private issue-tracker id. Cite a private project as "a
  private project".
- History counts: making a private repo public publishes every past commit. Start a fresh repo,
  or rewrite the history while it is still private, until no commit holds a setup detail.

## 4. Before every push

Read the diff, the commit messages, and the PR or issue text for setup details: the owner's
domains, hostnames, IP addresses, machine names, local paths, private repo or issue names, agent
names, personal data. Move any you find into the installation as configuration. A project may keep
a generic check in its own CI (a grep for home paths or email addresses); a reading by hand is
still the check, because no list knows every name.

## 5. Keep it light

Publishing needs no extra repos or bespoke infrastructure: the project's own CI, tests and
semantic-release are the process (`rules:global`: right-size, prior art first).
