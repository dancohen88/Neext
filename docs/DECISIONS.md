# Decisions

A lightweight architecture decision record (ADR) log. Add new entries at the bottom. To change a decision, add a new entry that supersedes the old one rather than editing it.

## 001 — Dev local, prod in Oracle Cloud Always Free (2026-10-14)
Dev runs on a local k3d cluster. Prod runs on k3s on Oracle Cloud's Always Free ARM tier.
**Why:** The Mac has 24 GB RAM, so two full stacks won't fit locally. A real cloud prod gives real networking, public TLS and real drift between environments, all at zero cost.
**Consequences:**
- Since June 2026 the free ARM allowance is **2 OCPU / 12 GB** (it was 4 / 24). Prod is deliberately lean, and its binding constraint is CPU, not RAM.
- All images are arm64, which matches the Mac.
- The home region is permanent, and ARM capacity can be scarce at signup.
- Oracle only reclaims an instance when CPU, network *and* memory all stay under 20% for 7 days. Prod's memory use alone keeps it above that. Confirm in Oracle's metrics after the first deploy.

## 002 — Java / Spring Boot, Maven (2026-10-14)
JDK 25 (Temurin), latest Spring Boot 4.x, Maven multi-module.
**Why:** This is the most common enterprise stack, with mature tooling for batch, Kafka and resilience. Maven is declarative and what most Spring shops use.
**Consequences:** Spring Boot uses more memory and starts more slowly than lighter stacks. Every service has strict memory limits and JVM flags tuned to them. Fixing JVM scale-up latency is a Layer 6 goal.

## 003 — Public GitHub monorepo and workflow (2026-10-14)
`dancohen88/Neext`, one monorepo. Work flows Issue → branch → PR → **owner reviews and merges**. `main` is protected. Required checks, Dependabot, Conventional Commits and a Projects board are introduced gradually.
**Why:** A public repo gets unlimited Actions minutes and free GHCR. A monorepo lets one change span service, chart and dashboard. Learning GitHub well is a goal in itself.
**Consequences:** No secrets in the repo, ever. CI builds only what changed (path filters).

## 004 — Docker Desktop as container runtime (2026-10-14)
**Why:** It's the best-known runtime and free for personal use.
**Consequences:** Docker Desktop is capped at 14 GB so the rest of the Mac stays usable. k3d runs inside it.

## 005 — Control centre runs outside the system under test (2026-10-14)
**Why:** The tool that injects faults and observes the system must keep working while the system fails. This is the control plane vs system-under-test split.
**Consequences:** It runs natively on macOS: not in either cluster, and not inside Docker Desktop, which dev shares (a separate failure domain). It reaches dev and prod only through external APIs, with prod over Tailscale.

## 006 — Ways of working (2026-10-14)
- Claude writes the code and explains each step.
- Each milestone's PR description records what was built, the concepts behind it and things to look up. `docs/learning/` holds one journal page per layer.
- Milestones take about an hour and end in a demo.
- Tool choices for each layer are made at that layer's kickoff.
**Why:** This is a learning project. The commentary has to outlast the chat.

## 007 — Domain: Neext, a parody online shop (2026-10-14)
The name is a play on the UK retailer Next, with original branding (no copied logos or styling). The first service is **catalog**: REST with OpenAPI (springdoc), Flyway migrations and Testcontainers integration tests.
**Why:** A shop gives a rich order flow for events, natural batch jobs and dramatic traffic spikes (a flash sale with a waiting room, Layer 6).

## 008 — Kubernetes from day one; Helm + Tilt; split dev namespaces (2026-10-14)
k3d from Layer 0. Each service has a Helm chart with `values-dev.yaml` / `values-prod.yaml`. Tilt deploys uncommitted code into `neext-local`. Argo CD manages `neext-dev`, which mirrors `main`. Shared platform components run once.
**Why:** Probes, autoscaling and rollouts are Kubernetes concepts, so Compose would be thrown away. Argo CD reverts any change that isn't in git, so Tilt and Argo CD must never manage the same namespace.
**Consequences:** App pods run twice in dev (about 1 GB at first).

## 009 — Website: Next.js in-cluster, BFF pattern (2026-10-14)
**Why:** Next.js is the dominant commercial choice. With the Next.js server calling the API, the browser never sees backend addresses, and login tokens can later stay server-side.
**Consequences:** The website is part of what gets scaled and broken. Load tests can hit both the website and the public API.

## 010 — Images: hand-written Dockerfiles, SHA tags, native arm64 CI (2026-10-14)
**Why:** Dockerfiles make every layer of the image visible. Commit-SHA tags make it clear what's running and allow clean rollbacks, unlike a floating `:latest`. GitHub's arm64 runners avoid slow emulation.

## 011 — PostgreSQL via CloudNativePG (2026-10-14)
**Why:** A production-grade operator that handles replicas, failover and backups, and an introduction to the operator pattern. Bitnami's free images moved to an unmaintained repo in 2025.

## 012 — Prod: walking skeleton on k3s, built with Terraform, private over Tailscale (2026-10-14)
- Prod first comes up in Layer 2, on one 2-core / 12 GB VM running k3s.
- Terraform runs from the Mac, with state in OCI Object Storage; it moves to GitHub Actions in Layer 8. cloud-init installs k3s and Tailscale.
- Admin access (Kubernetes API, Argo CD, SSH) is over Tailscale only. The public site stays offline until Layer 3.
**Why:**
- A walking skeleton exercises promotion and deals with cloud risks early.
- k3s is what k3d runs, so dev and prod run the same Kubernetes (dev/prod parity).
- Infrastructure as code makes "rebuild prod from scratch" a repeatable drill.
- No admin ports are open to the internet.
**Consequences:** Terraform state holds a Tailscale auth key, so use a single-use key and a private bucket. Revisit one VM vs two in Layer 8.

## 013 — Delivery: Argo CD GitOps; promotion by PR (2026-10-14)
Argo CD runs in both clusters. Image Updater runs in `argocd` mode for `neext-dev`: it sets the tag on the Argo CD application directly, with no git commit, because a commit would hit branch protection. Prod changes only when the owner merges a PR that bumps its image tags.
**Why:** With pull-based GitOps, no outside system holds the cluster's keys. Merging the promotion PR *is* the release.
**Consequences:** Dev's running tag is recorded in Argo CD, not git. Prod is fully defined in git.

## 014 — Secrets: Sealed Secrets (2026-10-14)
**Why:** A simple, Argo-native way to keep encrypted secrets in a public repo.
**Consequences:** Each cluster has its own key, backed up outside git (in a password manager). Restoring the key is part of the rebuild drill.

## 015 — Observability: self-hosted in dev, Grafana Cloud free tier for prod (2026-10-14)
**Why:** Prod's 12 GB can't hold Prometheus, Loki and Tempo next to the workload. Shipping telemetry to a hosted service is common practice.
**Consequences:** Dashboards and alerts are defined as code and provisioned to both. Free-tier limits are checked before load-testing prod. Details are decided at the Layer 5 kickoff.

## 016 — Simulated problems (2026-10-14)
- Scripted fault scenarios start in Layer 4. Blind incident drills, with time-to-detect and time-to-resolve logged, start in Layer 5, when Chaos Mesh and observability arrive.
- Faults are injected **outside git**: in a public repo a commit spoils the drill.
- Argo CD self-heal automatically reverts drift-type faults, so drills use faults it can't see: killed pods, network faults, resource stress, bad data.

## 017 — "API certification" means TLS certificates and authentication, added by layer (2026-10-14)
TLS and Keycloak arrive in Layer 3. mTLS between services arrives in Layer 8. Contract testing and API keys are not planned, but may be proposed when a layer starts.

## 018 — Scaling scope (2026-10-14)
Pod autoscaling (HPA, KEDA) is real. Node autoscaling is simulated by the control centre adding and removing k3d nodes, because fixed zero-cost capacity can't grow. In prod, experiments lean towards throttling and load shedding rather than scaling out.

## 019 — Vulnerability management (2026-10-17)
1. **Reduce exposure first.** Every port the dev cluster publishes binds to `127.0.0.1`. Prod admin access is over Tailscale only (Decision 012).
2. **Fix what we control.** Take patch releases promptly, and replace unmaintained images.
3. **Record what we can't fix yet.** When the fix depends on an upstream release, add it to [vulnerabilities.md](vulnerabilities.md) with a re-check trigger.
4. **Judge risk by reachability**, not raw severity counts.
5. **Scan our own images in CI from Layer 1**, with the scanner chosen at the Layer 1 kickoff.

**Why:** Docker Scout reported 66 critical CVEs across the dev images. Triage found the biggest real risk wasn't any CVE: port 8080 was published on every network interface. Most of the counts trace to a few libraries compiled into upstream binaries, which only the upstream maintainers can rebuild.
**Consequences:** `make scan` re-checks every image, including those inside k3s that Docker Desktop doesn't show. Run it at each layer kickoff and when upstream releases.

## Deferred to layer kickoffs
- Layer 1: image scanner for CI (Docker Scout, Trivy or Grype).
- Layer 3: gateway product, domain name.
- Layer 4: event streaming distribution.
- Layer 5: observability details, Grafana Cloud setup.
- Layer 6: flash-sale design.
- Layer 7: control centre design and tech.
- Layer 8: service mesh, one VM vs two.
