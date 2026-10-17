# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Neext is a learning and deep-dive project: a parody online shop (a play on the UK retailer Next) that simulates a production system, built up in layers. The flow is website → API gateway (auth, certificates, throttling) → Spring Boot microservices and batch jobs → PostgreSQL / events. On top of that sit simulated workload, observability, autoscaling and fault injection, driven by a control centre that runs outside the system. It's meant to be fun, so playful naming is welcome, but the branding stays original.

- [docs/ROADMAP.md](docs/ROADMAP.md): the layers, in build order. Check which layer we're on before adding components from a later one.
- [docs/DECISIONS.md](docs/DECISIONS.md): an ADR log. Add an entry for any new stack or architecture decision; supersede, don't rewrite. Tools for a layer are chosen at its kickoff, not ahead of time.

## Ways of working

- Claude writes the code and explains each step: the concept, the trade-off, and the name of the pattern so the user can look it up.
- Each milestone (about an hour, ending in a demo) has a GitHub Issue under its layer's Milestone and on the Projects board (https://github.com/users/dancohen88/projects/1).
- The work happens on a branch named `type/m<layer>.<n>-short-name` and arrives as a PR. **The user reviews and merges;** a ruleset blocks direct pushes to `main`.
- The PR description follows `.github/pull_request_template.md`. It's the learning write-up, and it starts with `Closes #<issue>`.
- PRs are squash-merged, so the PR title becomes the commit on `main`. Titles are Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` …).
- Each layer gets a journal page in `docs/learning/`, updated by each milestone's PR.

## Constraints that shape every change

- **Zero cost, commercially used tools.** Prefer free tools that companies run in production over toy alternatives.
- **Tight resources.**
  - Dev shares a Docker Desktop VM capped at 14 GB.
  - Prod is one Oracle ARM VM with 2 vCPUs and 12 GB. CPU is the scarcer resource.
  - Every workload needs explicit resource requests and limits. JVM flags are tuned to each container's limit.
- **arm64 images only.** Dev (Apple Silicon) and prod (Oracle Ampere) are both ARM.
- **Public repo.** No secrets, tokens or kubeconfigs in git. Secrets go in as Sealed Secrets.
- **Dev namespaces are split.**
  - `neext-local` is Tilt only.
  - `neext-dev` is Argo CD only and mirrors `main`.
  - Never let both manage the same namespace: Argo CD reverts anything not in git.
- **Prod changes only through git.** That means a promotion PR bumping image tags in prod values. Admin access is over Tailscale only.
- **Fault injection never goes through git.** It would spoil blind drills, and Argo CD would revert it anyway.
- **The control centre runs natively on macOS**, outside Docker Desktop and both clusters.

## Commands

There's no application code yet. Record build, test, single-test and deploy commands here as they're created.

- `brew bundle`: install or update the toolchain from the [Brewfile](Brewfile). `brew bundle check --verbose` lists anything missing.
- Java must be Temurin 25: `JAVA_HOME=$(/usr/libexec/java_home -v 25)`, set in `~/.zshrc`. Homebrew's Maven otherwise silently uses Homebrew's newer `openjdk`. Claude's shell may not have it, because it can be set up before `~/.zshrc` changes. Before any Java or Maven command, check that `mvn -v` reports Java 25. If it doesn't, export `JAVA_HOME` in the same command, or run it via `zsh -ic '…'`.
