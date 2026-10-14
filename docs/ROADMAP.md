# Roadmap

Neext is a learning platform. It's a parody online shop that simulates a production system end to end: website → API gateway → microservices and batch jobs → databases and events. On top of that sit simulated workload, observability and fault injection, all driven from a control centre that runs outside the system.

We build it in layers, and each layer leaves the system working and demoable. Each layer is broken into **milestones of about an hour that each end in a demo**. Tool choices for a layer are made in a short decision round when the layer starts, and logged in [DECISIONS.md](DECISIONS.md). The **Problems** lines list the faults to inject or the real issues to solve once that layer exists.

## Layer 0 — Foundations
- Toolchain: Docker Desktop (14 GB cap), k3d, kubectl, Helm, Tilt, JDK 25 (Temurin), Maven, k6.
- Public GitHub monorepo `dancohen88/Neext`. Protected `main`, a branch and PR per milestone, Issues and a Projects board for Layers 0–2.
- GitHub Actions skeleton on native arm64 runners; images to GHCR.
- Local `dev` k3d cluster.

## Layer 1 — First slice (dev)
- Next.js website → Spring Boot **catalog** service → PostgreSQL (CloudNativePG, Flyway migrations).
- The Next.js server calls the API (the BFF pattern), so the browser never sees backend addresses.
- Hand-written Dockerfiles, Helm charts, and Tilt for the inner loop in the `neext-local` namespace. k3d's built-in Traefik is the entry point.
- CI runs unit tests and Testcontainers integration tests, and builds images tagged with the git SHA.
- **Problems:** pod crash loops, failing readiness probes, DB connection pool exhaustion, JVM memory vs container limits.

## Layer 2 — Path to prod (walking skeleton)
- Oracle Cloud Always Free signup. Terraform (run from the Mac, state in OCI Object Storage) creates one 2-core / 12 GB ARM VM, and cloud-init installs k3s and Tailscale.
- Argo CD in both clusters:
  - `neext-dev` auto-deploys every merge to `main` via Image Updater.
  - Prod changes only through promotion PRs.
- Sealed Secrets in both clusters, with the sealing keys backed up outside git.
- Prod is private, reachable only over Tailscale. A trickle of synthetic traffic runs from inside the cluster.
- **Problems:** cloud capacity errors, cloud-init debugging, the first failed rollout and rollback, environment drift.

## Layer 3 — Edge: gateway, auth, certificates
- API gateway (product chosen at kickoff): routing, rate limiting / throttling.
- Keycloak: OAuth2 / OIDC. Tokens are held server-side by the Next.js BFF, and JWTs are validated at the gateway and the services.
- cert-manager: Let's Encrypt at the edge and an internal CA. Prod goes public (domain chosen at kickoff).
- **Problems:** expired certs, clock skew breaking JWTs, 429 storms, retry amplification, bots scanning the new public endpoint.

## Layer 4 — Events and batch
- Event streaming (Kafka via Strimzi or Redpanda, chosen at kickoff). Order flow: order → payment → inventory → shipping.
- Transactional outbox, idempotent consumers, dead-letter topics.
- Spring Batch jobs as Kubernetes CronJobs (e.g. nightly settlement, reports).
- **Scripted fault scenarios start here.** Faults are injected by hand until Chaos Mesh arrives.
- **Problems:** consumer lag, poison messages, duplicate delivery, rebalance storms, batch overlapping peak load.

## Layer 5 — Observability and chaos
- OpenTelemetry (Java agent) → metrics, logs and traces. Dev runs a self-hosted Grafana stack; prod ships to Grafana Cloud's free tier.
- Dashboards and alerts **as code**, provisioned into both. SLOs, burn-rate alerts, business dashboards.
- Chaos Mesh in dev.
- **Blind incident drills start here:** a hidden fault, diagnosed from telemetry alone, with time-to-detect and time-to-resolve logged.
- **Problems:** cardinality explosions, missing trace context across Kafka, noisy alerts, Grafana Cloud free-tier limits.

## Layer 6 — Workload, scaling, resilience
- k6 scenarios: steady, ramp, spike, soak; synthetic users with realistic behaviour mixes.
- Flash sale with a virtual waiting room.
- HPA on CPU/custom metrics; KEDA on consumer lag. Pod autoscaling is real; node autoscaling is simulated.
- Resilience4j: timeouts, circuit breakers, bulkheads; backpressure; load shedding.
- JVM scale-up latency: compare CDS, CRaC and GraalVM native images. This matters most on prod's 2 vCPUs.
- **Problems:** cold-start latency under spike, thundering herd, cascading failure, noisy neighbours, CPU throttling.

## Layer 7 — Control centre
- Runs natively on macOS, outside Docker Desktop and outside both clusters. It reaches prod over Tailscale.
- Start/stop load scenarios, trigger Chaos Mesh experiments, flip feature flags, view health across dev and prod, run blind drills, and simulate node autoscaling (adding/removing k3d nodes).

## Layer 8 — Prod hardening
- Backups and restore drills (CloudNativePG to object storage), the "rebuild prod from scratch" drill (including restoring the Sealed Secrets key), and mTLS between services (e.g. a service mesh).
- Terraform plan/apply moves into GitHub Actions.
- Revisit one VM vs two 1-core VMs (enables node-failure drills).
- **Problems:** failed upgrades, restore under pressure, certificate rotation.
