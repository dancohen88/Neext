# Field guide · Layer 0

How to operate what Layer 0 built: the toolchain, the local cluster, the GitHub workflow and CI. It's organised by task. For *why* things are the way they are, see the [Layer 0 journal](../learning/layer-0.md) and [DECISIONS.md](../DECISIONS.md).

Run every command from the repo root, `~/Sandbox/Neext`.

## Quick reference

| I want to… | Run |
|---|---|
| See every shortcut | `make` |
| Start the cluster | `make cluster-up` |
| Check the cluster is healthy | `make cluster-status` |
| Prove a request reaches a pod | `make smoke` |
| See memory and CPU use | `kubectl top nodes` · `kubectl top pods -A` · `docker stats` |
| Check files before pushing | `make lint` |
| Scan images for CVEs | `make scan` (slow, ~10 min) |
| Delete the cluster | `make cluster-down` |
| Install or update tools | `brew bundle` |
| Get back in sync after a merge | `git switch main && git pull` |

## Starting and stopping

**Starting a session**
1. Open **Docker Desktop** and wait until it shows as running. Nothing works without it.
2. Run `make cluster-up`. If the cluster already exists, this just confirms the nodes are `Ready`.
3. Optionally run `make smoke` to check the whole request path.

**Ending a session.** You have three options:
- **Leave it running.** It uses about 1.1 GB at idle.
- **Quit Docker Desktop.** The cluster pauses, and comes back by itself the next time Docker starts (its containers are set to `unless-stopped`).
- **`make cluster-down`.** Deletes the cluster entirely. Nothing is lost: its whole definition is in the repo, and `make cluster-up` rebuilds it in under a minute.

## Checking health

**What normal looks like**

| Check | Healthy |
|---|---|
| `make cluster-status` | 3 nodes `Ready`, both namespaces `Active`, and "No resources found" (no unhealthy pods) |
| `make smoke` | `✔ smoke passed: localhost:8080 → Traefik → pod` |
| `kubectl top nodes` | Control plane about 700 MiB; each worker 100–200 MiB |
| Docker Desktop → Containers | `k3d-neext-*` and `neext-registry` running |
| `docker port k3d-neext-serverlb` | Everything bound to `127.0.0.1`, never `0.0.0.0` |

**Where memory shows up.** Docker Desktop's **Containers** tab gives a quick look. `docker stats` gives a live table (press Ctrl+C to stop). `kubectl top` gives Kubernetes's own view, per node or per pod. The numbers differ slightly between them, because Docker measures whole containers and Kubernetes measures active ("working set") memory.

## Shipping a change (the GitHub workflow)

Every change follows the same path:
1. **Issue.** Each milestone has one, under its layer's Milestone and on the [project board](https://github.com/users/dancohen88/projects/1).
2. **Branch.** Named `type/m<layer>.<n>-short-name`, e.g. `docs/m0.6-field-guide`.
3. **PR.** The description follows the template and starts with `Closes #<issue>`. The title is a Conventional Commit (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`).
4. **CI.** The required `lint` check runs in about 8 seconds.
5. **You merge.** Review the PR, then click **Squash and merge**.

What happens automatically after the merge:
- The Issue closes, and the board moves it to **Done**.
- `main` gains one commit, named after the PR.
- The remote branch is deleted.

**Syncing afterwards**
```sh
git switch main && git pull
git branch -D <old-branch>   # see "not fully merged" below
```

**What `main` refuses.** Direct pushes, force-pushes, deletion, and merges with a red `lint` check. This applies to you too, because nobody is on the ruleset's bypass list.

## CI

- **What runs:** `make lint`, which is yamllint (YAML formatting) followed by kubeconform (Kubernetes manifests against the schema for our k3s version). CI runs exactly the same command, so a green `make lint` locally means green in CI.
- **Reading a failure:** on the PR, click **Details** next to the red **CI / lint**. The log shows the file and the problem, e.g. `additional properties 'replica' not allowed`.
- **Dependabot:** expect a weekly PR titled `ci: …` when GitHub Actions we use have updates. Review it and merge it like any other PR.

## Security routine

- **At each layer kickoff,** run `make scan`. Compare the results with the [vulnerability register](../vulnerabilities.md) and update it.
- **When k3s, k3d or the registry release,** follow the register's "re-check when" list.
- **Keep the bind rule.** Anything published from the Mac binds to `127.0.0.1`. To verify, `curl --max-time 3 http://$(ipconfig getifaddr en0):8080/` should time out.

## Troubleshooting

These are the problems we've actually hit, by symptom.

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop isn't running | Open Docker Desktop and wait for it to start |
| `mvn -v` shows Java 27 | `JAVA_HOME` isn't set in this terminal, so Homebrew's Maven falls back to its own JDK | Open a new terminal, or run `source ~/.zshrc` |
| `make smoke` fails right after `cluster-up` | Traefik is still installing; k3s adds it after startup | Wait a minute. `kubectl --context k3d-neext -n kube-system get pods` shows its progress |
| Something else is using port 5000 | macOS AirPlay Receiver | Nothing to fix: our registry uses 5005 |
| `git branch -d` says "not fully merged" after a merge | Squash merging creates a new commit, so git doesn't recognise the branch's commits | Check `git diff --quiet <branch> main` reports nothing, then `git branch -D <branch>` |
| A push straight to `main` was *accepted* | The commit was the head of an open, mergeable PR, so GitHub counted it as merging that PR | Expected. Unapproved commits are rejected |
| Merge button greyed out | The required `lint` check failed or hasn't finished | Open **Details**, fix the problem, push again |
| `make scan` prints `? scan failed, try again` | Docker Scout's online lookup failed for that image | Run it again |
| kubectl shows the wrong cluster | It's using whatever the current context is | Always pass `--context k3d-neext`, as the Makefile does |

## Where things live

| Path | What |
|---|---|
| `Brewfile` | The toolchain |
| `Makefile` | Every routine command (`make` lists them) |
| `platform/k3d/cluster.yaml` | Cluster definition: nodes, k3s version, ports, registry |
| `platform/namespaces.yaml` | `neext-local` (Tilt) and `neext-dev` (Argo CD) |
| `platform/smoke-test.yaml` | What `make smoke` deploys |
| `.yamllint.yaml` | Lint rules |
| `.github/workflows/ci.yml` | CI |
| `.github/dependabot.yml` | Dependabot |
| `.github/pull_request_template.md` | PR template |
| `docs/` | Roadmap, decisions, vulnerability register, learning journal, field guides |
