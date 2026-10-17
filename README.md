# Neext

**Always one e ahead.** Neext is a parody high-street shop, built to be scaled, throttled and broken on purpose.

It's a learning project. It builds a production-style system end to end and then puts it under realistic pressure:

- a website, an API gateway with authentication and TLS, Spring Boot microservices and batch jobs, PostgreSQL and an event stream
- simulated shoppers, observability, autoscaling and throttling
- injected faults and blind incident drills, run from a control centre that sits outside the system

Everything uses free tools that companies run in production. Dev runs on a laptop and prod runs in Oracle Cloud's free tier.

## Status

**Layer 0 · Foundations** is in progress. Track it on the [project board](https://github.com/users/dancohen88/projects/1) or under [milestones](https://github.com/dancohen88/Neext/milestones).

## Docs

| | |
|---|---|
| [Roadmap](docs/ROADMAP.md) | The nine layers, in build order, and the problems each one unlocks |
| [Decisions](docs/DECISIONS.md) | Architecture decision log, with the reasoning behind each choice |
| [Blueprint](docs/blueprint.html) | Interactive architecture diagrams and the shop's brand kit (download it and open it in a browser) |
| [Learning journal](docs/learning/) | One page per layer: concepts, with links to the PRs that introduced them |

## How work happens

Each milestone is an Issue, a branch and a pull request. `main` only changes through squash-merged PRs. PR titles follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:` …), and each PR description doubles as a learning write-up.

---

Neext is a parody. It is not affiliated with Next plc, and the products are fictional.
