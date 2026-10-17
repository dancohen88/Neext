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

The aim was a real multi-node Kubernetes cluster on the laptop, defined in the repo and created with one command.

**What we set up**
- [`platform/k3d/cluster.yaml`](../../platform/k3d/cluster.yaml) defines the cluster:
  - 1 control-plane node and 2 worker nodes, each a Docker container
  - k3s pinned to v1.35.5, the same version prod will run
  - `localhost:8080` mapped to Traefik
  - a local image registry for Tilt
- [`platform/namespaces.yaml`](../../platform/namespaces.yaml): `neext-local` (Tilt) and `neext-dev` (Argo CD, from Layer 2).
- A [`Makefile`](../../Makefile) as the repo's task runner. `make` lists the targets.
- `make smoke` proves the whole ingress path works (`localhost:8080` → k3d load balancer → Traefik → Service → Pod), then removes itself.

**Numbers worth remembering**
- Creating the cluster takes about 45 seconds.
- At idle it uses about 1.1 GB, three-quarters of it the control-plane node.

**Problems found and fixed**
- **Port 5000 is taken on macOS**, by ControlCenter's AirPlay Receiver. Most local-registry tutorials use 5000, so the registry listens on **5005** on the Mac. Inside the cluster it's still `neext-registry:5000`.
- **Traefik isn't ready the moment the cluster is.** k3s installs it with a Helm job after startup, so the smoke test waits for its pod to be ready rather than assuming.

**Concepts to look up**
- *Kubernetes in Docker* (k3d, kind): nodes as containers, and why that's good enough for dev.
- *Control plane vs worker nodes*.
- *Ingress and ingress controllers*: how an outside request finds a Service. Traefik is k3s's built-in controller.
- *Deployment → ReplicaSet → Pod, and Service*: the four objects in the smoke test.
- *Readiness probes*: Kubernetes sends traffic to a pod only once its `/health` check passes.
- *Resource requests vs limits*: even the smoke pod declares them (a CLAUDE.md rule).
- *kubeconfig contexts*: why the Makefile always passes `--context k3d-neext`. Once prod exists, the wrong current context could point a command at prod.
- *Idempotency*: running `make cluster-up` twice is safe.
- *Smoke tests*: a quick end-to-end check that the basics work, before deeper testing.
- *Self-documenting Makefile*: the `## comment` pattern behind `make help`.

## M0.4 · CI skeleton

The aim was a pipeline that checks every PR automatically, and a rule that won't let a failing one merge.

**What we set up**
- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml): a `lint` job on GitHub's free arm64 runner. It runs on every PR to `main` and every push to `main`, in about 7–9 seconds.
- `make lint` runs two different kinds of check. CI runs exactly the same command, so a green `make lint` on your Mac means green in CI.
  - **Format** (`yamllint`, with rules in [`.yamllint.yaml`](../../.yamllint.yaml)): is every YAML file well formed and consistently styled?
  - **Schema** (`kubeconform`, against the Kubernetes 1.35.5 schemas): is every manifest a valid Kubernetes object?
- The `main` ruleset now requires the `lint` check, pinned to GitHub Actions so no other app can report a fake green.
- [`.github/dependabot.yml`](../../.github/dependabot.yml): a weekly PR when the Actions we use have new versions, titled `ci: …` to follow the house rules.

**The demo**
1. A deliberate typo, `replica: 1` instead of `replicas: 1`, was pushed to the PR. It's perfectly valid YAML, so yamllint passed it. kubeconform rejected it: `additional properties 'replica' not allowed`. CI went red in 6 seconds and the PR's merge state became `BLOCKED`.
2. A `git revert` commit undid the typo. CI went green and the merge state became `CLEAN`. Reverting adds a new commit rather than rewriting history, so the shared branch never needed a force-push. Squash merging folds all of it into one commit on `main`.

**Supply-chain hygiene in the workflow**
- **Actions are pinned to commit SHAs** (`actions/checkout@3d3c42e…`), not tags like `v7`. A tag can be moved to point at different code; a commit SHA can't. Dependabot understands SHA pins and keeps them current.
- **Downloads are checksum-verified.** kubeconform's tarball is checked against the release's `CHECKSUMS` file before it runs.
- **Least privilege.** The workflow's token can only read the repo (`permissions: contents: read`), and checkout doesn't leave credentials behind (`persist-credentials: false`).

**Concepts to look up**
- *Continuous integration (CI)*: every change is checked automatically before it lands.
- *Required status checks*, and the *strict* "branches must be up to date" option (left off here; it matters on busy team repos).
- *Linting vs schema validation*: format vs meaning.
- *"Shift left"*: catching mistakes as early, cheaply and close to the author as possible.
- *Software supply-chain security*: pinning by SHA, checksums, least-privilege tokens. Also look up the *tj-actions* compromise (2025), where a moved tag delivered malicious code.
- *`git revert` vs `git reset`*: undoing by adding history vs rewriting it.
- *Dependabot version updates*.

## M0.5 · Triaging container CVEs

Docker Desktop's image list showed **66 critical and about 370 high CVEs** across seven images. The aim was to work out which mattered, fix what we could, and record the rest honestly. The full result is in the [vulnerability register](../vulnerabilities.md).

**How the triage went**
1. **Break the counts down by package.** Nearly all of them came from Go libraries compiled into upstream programs (k3s, the registry, k3d's proxy), not from anything we wrote or configured.
2. **Look for newer releases.**
   - k3s had 4 newer **patch** releases on the same 1.35 line. These are mostly fixes, so they're low-risk to take.
   - k3d's default registry image, `registry:2`, had been superseded by `registry:3`.
   - k3d itself had no newer release.
3. **Check exposure.** The most important finding was **not a CVE**: port 8080, the cluster's front door, was published on **every network interface**. Anyone on the same Wi-Fi could reach it, and it's served by k3d-proxy, the most vulnerable image. A one-word fix (`127.0.0.1:8080:80`) took it off the network. That was verified by trying to reach it through the Mac's network address.
4. **Fix, measure, record.**
   - k3s criticals went from 16 to 13 and the registry's from 6 to 3, and the demo leftovers were deleted.
   - The rest is recorded with a "re-check when" trigger, because the fixes need upstream releases.
5. **Find the blind spot.** Images running *inside* k3s (Traefik, CoreDNS, …) live in k3s's own image store, so Docker Desktop never shows them. They carried another 27 criticals. `make scan` now covers both stores.

**Concepts to look up**
- *CVE* and *CVSS* severity scores, and why a count isn't a risk measure.
- *Reachability and exposure*: a vulnerability nobody can reach matters far less.
- *Attack surface reduction*, and binding to `127.0.0.1` vs `0.0.0.0`.
- *Semantic versioning*: patch vs minor vs major, and why patches are safe to take promptly.
- *Software composition analysis (SCA)*: how scanners find libraries inside compiled binaries.
- *Risk acceptance* and a *vulnerability register*: recording a decision not to fix yet, with a reason and a trigger.
- *Docker Scout* (Docker Desktop's scanner); alternatives include Trivy and Grype.

## Layer 0 wrap-up

Layer 0 is done:
- `main` is protected and changes only through checked, squash-merged PRs.
- The toolchain is one `brew bundle` away.
- A three-node Kubernetes cluster comes up in about 45 seconds and idles at about 1.1 GB.
- CI checks every change in seconds.

None of the shop exists yet. That starts in Layer 1.
