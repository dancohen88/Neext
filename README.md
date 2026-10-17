# Neext

[![CI](https://github.com/dancohen88/Neext/actions/workflows/ci.yml/badge.svg)](https://github.com/dancohen88/Neext/actions/workflows/ci.yml)

**Always one e ahead.** Neext is a parody high-street shop, built to be scaled, throttled and broken on purpose.

It's a learning project. It builds a production-style system end to end and then puts it under realistic pressure:

- a website, an API gateway with authentication and TLS, Spring Boot microservices and batch jobs, PostgreSQL and an event stream
- simulated shoppers, observability, autoscaling and throttling
- injected faults and blind incident drills, run from a control centre that sits outside the system

Everything uses free tools that companies run in production. Dev runs on a laptop and prod runs in Oracle Cloud's free tier.

## Status

**Layer 0 · Foundations** is complete. **Layer 1 · First slice** is next. Track it on the [project board](https://github.com/users/dancohen88/projects/1) or under [milestones](https://github.com/dancohen88/Neext/milestones).

## Getting started

You'll need macOS on Apple Silicon with [Homebrew](https://brew.sh) installed.

1. **Install the toolchain.** Run `brew bundle` from the repo root. The [Brewfile](Brewfile) lists every tool. The installers ask for your password.
2. **Set up Docker Desktop.** Open it once and accept the terms. In **Settings → Resources**, set **Memory to 14 GB**. Leave its built-in Kubernetes **off**, because k3d provides the cluster.
3. **Pin Java to 25 (LTS).** Add this line to `~/.zshrc`, then open a new terminal:
   ```sh
   export JAVA_HOME=$(/usr/libexec/java_home -v 25)
   ```
   Homebrew's Maven otherwise uses its own, newer JDK.
4. **Check the setup.** `brew bundle check` should report everything installed, and `mvn -v` should show Java version 25.
5. **Start the dev cluster.** Run `make cluster-up`, then `make smoke` to check the setup end to end. Run `make` on its own to see every command.

## Docs

| | |
|---|---|
| [Roadmap](docs/ROADMAP.md) | The nine layers, in build order, and the problems each one unlocks |
| [Decisions](docs/DECISIONS.md) | Architecture decision log, with the reasoning behind each choice |
| [Blueprint](docs/blueprint.html) | Interactive architecture diagrams and the shop's brand kit (download it and open it in a browser) |
| [Learning journal](docs/learning/) | One page per layer: concepts, with links to the PRs that introduced them |
| [Field guides](docs/field-guide/) | One page per layer: how to operate what it built, plus troubleshooting |

## How work happens

Each milestone is an Issue, a branch and a pull request. `main` only changes through squash-merged PRs. PR titles follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:` …), and each PR description doubles as a learning write-up.

---

Neext is a parody. It is not affiliated with Next plc, and the products are fictional.
