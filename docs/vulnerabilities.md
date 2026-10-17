# Vulnerability register

This lists the known CVEs in the images Neext runs, what we did about each, and what we've accepted for now. The policy behind it is [Decision 019](DECISIONS.md). Re-scan with `make scan`.

**Last triaged:** 2026-10-17 (M0.5, [#9](https://github.com/dancohen88/Neext/issues/9)). Counts are from Docker Scout, as critical / high.

## Dev cluster images (shown in Docker Desktop)

| Image | Before | After | Action |
|---|---|---|---|
| `rancher/k3s` | v1.35.5: 16 / 55 | v1.35.9: 13 / 35 | Upgraded to the latest patch release on the 1.35 line. |
| `registry` (local registry) | `2`: 6 / 39 | `3.1.2`: 3 / 14 | Replaced k3d's default `registry:2`, which is unmaintained (Go 1.20, 2023). |
| `ghcr.io/k3d-io/k3d-proxy:5.9.0` | 34 / 191 | 34 / 191 | **Accepted.** No newer k3d release. Its only port is now bound to `127.0.0.1`. |
| `ghcr.io/k3d-io/k3d-tools:5.9.0` | 6 / 34 | 6 / 34 | **Accepted.** No newer k3d release. It exposes no ports. |
| `alpine`, `hello-world`, `docker/welcome-to-docker` | 0–4 / 1–28 | removed | Leftovers from demos and Docker Desktop onboarding. |

## Images inside k3s (not shown in Docker Desktop)

These ship with k3s and update with it. Docker Desktop never lists them, because they live in k3s's own image store, not Docker's.

| Image | Critical / high | Exposure |
|---|---|---|
| `rancher/klipper-helm:v0.13.3-build20260727` | 11 / 32 | A one-off job that installs Traefik at startup, then exits. |
| `rancher/mirrored-library-traefik:3.7.13` | 5 / 22 | The only one that receives outside traffic, via `127.0.0.1:8080` only. |
| `rancher/local-path-provisioner:v0.0.37` | 4 / 19 | Internal only. |
| `rancher/mirrored-metrics-server:v0.9.0` | 4 / 27 | Internal only. |
| `rancher/mirrored-coredns-coredns:1.14.7` | 3 / 33 | Internal only. |
| `rancher/klipper-lb:v0.4.17` | 0 / 0 | — |

## Why the remainder is accepted

Every remaining critical CVE in k3s and the registry comes from four Go libraries compiled into upstream binaries. Fixed versions of the libraries exist, but k3s and the registry haven't released builds that use them yet:

| Library | Fixed in |
|---|---|
| Go standard library | 1.26.9 |
| `golang.org/x/crypto` | 0.52.0 / 0.55.0 |
| `golang.org/x/net` | 0.60.0 |
| `google.golang.org/grpc` | 1.79.3 |

A scanner sees *which version* is present, not whether the program ever reaches the vulnerable code. The count is a prompt to look, not a measure of risk.

The exposure is low. This is a dev cluster on a laptop, and every port it publishes is bound to `127.0.0.1`.

**Re-check when** any of these release, or at the start of each layer:
- k3s newer than v1.35.9
- the registry newer than 3.1.2
- k3d newer than 5.9.0
