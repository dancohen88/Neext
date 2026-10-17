# Layer 0 · Foundations

The aim of this layer is to make a place to work before building anything: house rules on GitHub, a toolchain defined as code, a local Kubernetes cluster and a first CI pipeline.

## M0.1 · House rules

Before any code exists, decide how code is allowed to arrive. Every later change follows the path set up here.

**What we set up**
- `main` is protected by a **ruleset**: changes arrive only through pull requests, and force-pushes and branch deletion are blocked. This applies to the repo owner too.
- **Squash merging only.** Each PR becomes a single commit on `main`, titled with the PR title, and merged branches are deleted automatically.
- A **PR template** pre-fills every PR description with the learning write-up sections.
- **Issues** describe each milestone. A **Milestone** groups them per layer and shows progress. The **Projects board** shows status (Todo, In Progress, Done) and moves items to Done automatically when they close.
- **Closing keywords:** writing `Closes #1` in a PR description closes Issue #1 when the PR merges.

**Concepts to look up**
- *Trunk-based development*: one long-lived branch (`main`), with short-lived branches merged back quickly.
- *Branch protection vs rulesets*: rulesets are GitHub's newer system. They layer, can target many branches, and have explicit bypass lists.
- *Squash vs merge commit vs rebase*: three ways to land a PR, trading history detail against readability.
- *Conventional Commits*: structured commit titles that tools can later turn into changelogs and version numbers.
- *Linking PRs to issues*: GitHub's closing keywords.

**What actually happened (a real lesson)**

The demo was meant to show GitHub rejecting a direct push to `main`. Instead, `git push origin chore/m0.1-house-rules:main` **succeeded**, and PR #5 showed as merged.

The reason: the pushed commit was exactly the head commit of open PR #5, and that PR already met every rule (zero approvals required, no open conversations). GitHub treats pushing a mergeable PR's own commit to the base branch as **merging that PR from the command line**. GitHub's rule-suite log recorded the push as a `pass`.

Rerunning the demo with an empty commit that no PR had approved was rejected (`fail`). So "require a pull request" really means *nothing reaches `main` unless a PR has already approved it*.

How it was diagnosed: GitHub keeps a log of how rulesets judged each push (**rule suites**). It showed the ruleset was active, nobody could bypass it, and this push passed. That ruled out "the rule isn't working" and pointed to "the rule allowed this push on purpose".

## M0.2 · Workshop

The aim was to install the whole toolchain from a file, so any Mac can be set up with one command.

**What we set up**
- A [Brewfile](../../Brewfile), installed with `brew bundle`: Docker Desktop, k3d, kubectl, Helm, Tilt, Temurin JDK 25, Maven, k6.
- Docker Desktop's Linux VM capped at 14 GB. It reports about 13.6 GiB, because the VM's kernel keeps a slice for itself.
- `JAVA_HOME` pinned to Temurin 25 in `~/.zshrc`.

**Problems found and fixed**
- **The newest JDK isn't the right one.** The plain `temurin` cask now installs JDK 27. Java alternates **LTS** releases (21, 25, …), which get years of fixes, with short-lived feature releases. So the Brewfile pins `temurin@25`.
- **The wrong JDK came in through a dependency.** Homebrew's `maven` depends on Homebrew's own `openjdk` (27). That dependency is *keg-only*: installed but hidden from the rest of the system. Even so, `mvn -v` reported Java 27, because Homebrew's `mvn` wrapper falls back to it whenever `JAVA_HOME` is unset. Setting `JAVA_HOME` fixed it. This is a classic **transitive dependency** surprise: you didn't ask for a JDK 27, but something you asked for brought one.

**Concepts to look up**
- *Toolchain as code*: Brewfile and `brew bundle` (cousins: `.tool-versions` / asdf, mise, Nix).
- *Homebrew formulae vs casks*: command-line tools vs macOS apps. Also *keg-only* formulae.
- *Java LTS release cadence*, and `JAVA_HOME`.
- *Containers on macOS*: Docker Desktop runs a Linux VM, and containers share *its* kernel, not macOS's.
- *Multi-arch images and manifest lists*: why `docker pull alpine` fetched the arm64 build automatically.
- *macOS Local Network privacy*, and the *least privilege* principle.

## M0.3 · Local dev cluster

_To come._

## M0.4 · CI skeleton

_To come._
