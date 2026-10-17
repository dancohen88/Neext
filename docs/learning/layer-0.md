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

## M0.2 · Workshop

_To come._

## M0.3 · Local dev cluster

_To come._

## M0.4 · CI skeleton

_To come._
