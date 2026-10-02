# genieacs-container - AI Assistant Configuration

> **Project Context:** This is an open-source project (110+ stars). Consider community guidelines and contribution standards.

## Persona

You assist developers working on genieacs-container.

Project description: Production-ready Docker image and Helm chart for [GenieACS](https://genieacs.com), an open-source TR-069 (CWMP) Auto Configuration Server. Multi-arch (amd64/arm64), non-root runtime, integrated log rotation, supervisord process management.

## Tech Stack

- **Dockerfile:** Multi-stage build (3 stages: build, services helper, final)
- **Base images:** `node:24-bookworm` (build), `debian:bookworm-slim` (final)
- **Process manager:** supervisord (manages 4 GenieACS services)
- **Privilege handling:** gosu (drops from root to `genieacs` user after cron start)
- **Log rotation:** logrotate + cron daemon
- **Helm chart:** Kubernetes deployment with Bitnami MongoDB subchart
- **CI/CD:** GitHub Actions (Docker build, Helm chart-releaser)
- **Database:** MongoDB (external dependency, not bundled in image)

## Repository & Infrastructure

- **Host:** GitHub ([GeiserX/genieacs-container](https://github.com/GeiserX/genieacs-container))
- **License:** GPL-3.0
- **Commits:** Follow [Conventional Commits](https://conventionalcommits.org) format
- **Versioning:** Custom 4-part scheme — see [Versioning Scheme](#versioning-scheme) below
- **CI/CD:** GitHub Actions (`ci.yml` for Docker, `release-chart.yml` for Helm, `upstream-check.yml` for monitoring)
- **Docker Image:** `drumsergio/genieacs` on Docker Hub
- **Helm Repo:** `https://geiserx.github.io/genieacs-container` (GitHub Pages)
- **Upstream:** [genieacs/genieacs](https://github.com/genieacs/genieacs) on GitHub
- **Services config:** [GeiserX/genieacs-services](https://github.com/GeiserX/genieacs-services) (supervisord config, per-version branches)
- **Related:** [GeiserX/genieacs-mcp](https://github.com/GeiserX/genieacs-mcp) (MCP server for AI integration)

## Versioning Scheme

This project uses a **4-part version** that tracks the upstream GenieACS release:

```
{UPSTREAM_MAJOR}.{UPSTREAM_MINOR}.{UPSTREAM_PATCH}.{DOCKER_RELEASE}
```

**Example:** `1.2.13.6` means upstream GenieACS `v1.2.13`, Docker release `6`.

### Rules

- The first 3 digits **always match** the upstream GenieACS version (`ARG GENIEACS_VERSION` in the Dockerfile)
- The 4th digit (`DOCKER_RELEASE`) auto-increments on every push to main via CI
- When upstream releases a new version (e.g., `1.2.14`), the first Docker release is `1.2.14.0`
- Git tags use a `v` prefix: `v1.2.13.6` (Docker Hub tags omit it: `1.2.13.6`)
- **NEVER** reuse or force-retag an existing version. Tags only go forward.
- Helm chart versions are **independent** (semver: `0.2.2`, `0.2.3`, etc.) but `appVersion` in `Chart.yaml` tracks the Docker image version

### Version References in the Repo

When the upstream version changes, update **all** of these:

| File | Line | Example |
|------|------|---------|
| `Dockerfile` | `ARG GENIEACS_VERSION=v...` | `ARG GENIEACS_VERSION=v1.2.14` |
| `Dockerfile` | `--branch ...` (services clone) | `--branch 1.2.14` |
| `Dockerfile` | Header comment (cosmetic) | `# GenieACS v1.2.14.0 Dockerfile` |
| `docker-compose.yml` | `image:` tag | `drumsergio/genieacs:1.2.14.0` |
| `charts/genieacs/Chart.yaml` | `appVersion` | `"1.2.14.0"` |

The CI auto-increments the 4th digit and handles tagging. Only the Dockerfile lines (rows 1-2) are **required** for a new upstream release — the rest are optional repo consistency updates.

## CI/CD Workflows

### `ci.yml` — CI, Release & Docker Publish

**Triggers:**
- **Pull requests** to `main` — runs the `test` job (build + smoke test)
- **Push to `main`** — runs `test` then `release` (only when `Dockerfile`, `entrypoint.sh`, `config/**`, or the workflow itself changes)
- **Manual dispatch** — optional `version_override` input to set an exact version

**Jobs:**
1. **`test`**: Builds the Docker image, starts it with a MongoDB service container, verifies the UI responds on port 3000. This is a **required status check** on the branch ruleset.
2. **`release`**: Auto-increments the 4th version digit, builds multi-arch (amd64/arm64), pushes to Docker Hub, creates a git tag + GitHub Release with auto-generated notes.

**Auto-increment logic:**
1. Reads `GENIEACS_VERSION` from the Dockerfile (e.g., `v1.2.13` -> `1.2.13`)
2. Finds the latest `v1.2.13.*` tag
3. Increments the 4th digit by 1
4. If no matching tags exist (new upstream), starts at `.0`

### `release-chart.yml` — Release Helm Chart

Triggers on push to `main` when `charts/genieacs/**` changes. Uses [chart-releaser](https://github.com/helm/chart-releaser-action) to package and publish to GitHub Pages.

**Important:** Commits from `ci.yml` (via GITHUB_TOKEN) do NOT trigger this workflow. Helm chart releases require a separate push — either manual or via workflow dispatch.

### `upstream-check.yml` — Check Upstream GenieACS

Runs **weekly** (Monday 8 AM UTC) and on manual dispatch. Compares the `GENIEACS_VERSION` in the Dockerfile against the latest upstream release. If a newer version exists, creates a GitHub issue with step-by-step update instructions. Deduplicates — won't create an issue if one already exists for that version.

## Git Workflow

- **Workflow:** Create feature branches and submit pull requests
- Do NOT commit directly to main branch (branch protection enforced)
- Create descriptive branch names (e.g., `feat/logrotate`, `fix/security-context`)
- The `test` CI check must pass before merging
- Squash merge PRs to keep main history clean

## Deployment Workflow

### Regular Changes (auto-release)

1. Create feature branch, push, open PR
2. CI runs `test` job — must pass
3. Squash-merge to `main`
4. CI auto-releases: build -> push to Docker Hub -> git tag -> GitHub Release
5. (Optional) Update `docker-compose.yml` and `Chart.yaml` references

### New Upstream Version

1. The `upstream-check.yml` workflow creates an issue when a new version is detected
2. Ensure [GeiserX/genieacs-services](https://github.com/GeiserX/genieacs-services) has a branch for the new version
3. Update the 2 lines in `Dockerfile` (see [Version References](#version-references-in-the-repo))
4. Push to `main` — CI auto-releases `vX.Y.Z.0`

### Helm Chart Release

1. Update `charts/genieacs/Chart.yaml`: bump `appVersion` to match Docker image, increment chart `version`
2. Push to `main` — `release-chart.yml` auto-packages and publishes to GitHub Pages

## Boundaries

### Always (do without asking)

- Read any file in the repository
- Modify `Dockerfile`, `entrypoint.sh`, `config/**`
- Modify Helm chart templates and values
- Update CI/CD workflows
- Update documentation and README

### Ask First

- Add new dependencies to the Docker image (affects image size)
- Change exposed ports or the supervisord service list
- Modify the Helm chart's MongoDB subchart configuration
- Structural changes to the multi-stage build

### Never

- Modify `.env` files or commit secrets
- Force push to git
- Reuse existing version tags
- Remove multi-arch support (amd64/arm64)
- Change the upstream GenieACS source (must come from `genieacs/genieacs`)

## Code Style

- **Dockerfile:** Follow [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/). Minimize layers, clean up apt lists, use `--no-install-recommends`.
- **Shell scripts:** POSIX-compatible (`#!/bin/sh`), no bashisms. Keep entrypoint minimal.
- **Helm charts:** Follow [Helm best practices](https://helm.sh/docs/chart_best_practices/). Use `_helpers.tpl` for shared logic.
- **YAML:** 2-space indentation, no trailing whitespace.
- **Commit messages:** `type: description` format (e.g., `fix: resolve logrotate config syntax`, `feat(helm): add MongoDB subchart`).

## Key Architecture Decisions

### Multi-Stage Build (3 stages)

1. **Build stage** (`node:24-bookworm`): Clones upstream GenieACS, runs `npm ci` + `npm run build`. Heavy build tools (git, python3, make, g++) stay in this stage.
2. **Services helper** (`debian:bookworm-slim`): Clones `GeiserX/genieacs-services` for the supervisord config and `run_with_env.sh` helper. Uses a per-version branch (e.g., `1.2.13`).
3. **Final image** (`debian:bookworm-slim`): Copies Node runtime + built GenieACS from stage 1, copies supervisord config from stage 2. Installs only runtime deps (supervisor, cron, gosu, logrotate).

### Privilege Model

The container starts as root to launch the cron daemon (required for logrotate), then immediately drops to the `genieacs` user (UID 999) via `gosu`. Supervisord runs as `genieacs` and manages the 4 GenieACS processes.

### Four GenieACS Services

Managed by supervisord (`/etc/supervisor/conf.d/genieacs.conf` from genieacs-services repo):

| Service | Port | Purpose |
|---------|------|---------|
| `genieacs-cwmp` | 7547 | TR-069 CWMP (CPE communication) |
| `genieacs-nbi` | 7557 | Northbound Interface (REST API) |
| `genieacs-fs` | 7567 | File Server (firmware uploads) |
| `genieacs-ui` | 3000 | Web UI |

### Helm Chart MongoDB Integration

The chart includes Bitnami MongoDB as an optional subchart (`mongodb.enabled: true` by default). For external MongoDB, set `mongodb.enabled: false` and configure `externalMongodb.url`. The `envFrom` and `extraEnvVars` fields support injecting credentials from Kubernetes Secrets.

## Environment Variables

### GenieACS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GENIEACS_MONGODB_CONNECTION_URL` | *(required)* | MongoDB connection string |
| `GENIEACS_UI_JWT_SECRET` | `changeme` | JWT secret for UI auth — **change in production** |
| `GENIEACS_CWMP_ACCESS_LOG_FILE` | — | Path for CWMP access log |
| `GENIEACS_NBI_ACCESS_LOG_FILE` | — | Path for NBI access log |
| `GENIEACS_FS_ACCESS_LOG_FILE` | — | Path for FS access log |
| `GENIEACS_UI_ACCESS_LOG_FILE` | — | Path for UI access log |
| `GENIEACS_DEBUG_FILE` | — | Path for debug log (YAML format) |
| `GENIEACS_EXT_DIR` | `/opt/genieacs/ext` | Extensions directory |

All `GENIEACS_*` env vars are passed through to the services via `run_with_env.sh`. See [GenieACS wiki](https://github.com/genieacs/genieacs/wiki) for the full list.

### Volumes

| Path | Purpose |
|------|---------|
| `/opt/genieacs/ext` | Custom extension scripts |
| `/var/log/genieacs` | Logs (rotated daily, 30-day retention) |

## Important Files to Read

- `Dockerfile` — Multi-stage build, version ARGs, all image layers
- `entrypoint.sh` — Container startup (cron + gosu privilege drop)
- `config/genieacs.logrotate` — Log rotation config (daily, 30 days, compressed)
- `docker-compose.yml` — Reference deployment with MongoDB, health checks, optional sim/mcp
- `charts/genieacs/Chart.yaml` — Helm chart metadata, dependencies, version tracking
- `charts/genieacs/values.yaml` — All configurable Helm values (ports, probes, security, resources)
- `charts/genieacs/templates/deployment.yaml` — Main K8s deployment spec
- `.github/workflows/ci.yml` — Build, test, auto-release pipeline
- `.github/workflows/upstream-check.yml` — Weekly upstream version monitor
- `.github/workflows/release-chart.yml` — Helm chart packaging and GitHub Pages publishing
- `.github/cr.yaml` — Chart-releaser configuration
- `CHANGELOG.md` — Version history and migration notes

## Self-Improving Configuration

This file should evolve as the project grows:

1. When you learn new project patterns or conventions, suggest updates to this configuration file
2. Track corrections made to suggestions and update relevant sections
3. Note any recurring issues or debugging insights in a "Learned Patterns" section below

### Learned Patterns

- **Docker image version != upstream version.** The first 3 digits track upstream GenieACS; the 4th is the Docker release counter. Never confuse `1.2.13` (upstream) with `1.2.13.6` (Docker image).
- **genieacs-services repo uses per-version branches** (e.g., `1.2.13`). When upstream updates, a new branch must exist in that repo before updating the Dockerfile.
- **Helm chart versions are independent** from Docker image versions. Always bump both `appVersion` and `version` in `Chart.yaml` when releasing a new chart.
- **GITHUB_TOKEN commits don't trigger other workflows.** The auto-release in `ci.yml` cannot trigger `release-chart.yml` — Helm chart releases require a separate push.
- **Always use LTS versions of Node.js (even-numbered: 22, 24, 26…).** Odd-numbered "Current" releases (23, 25, 27…) can break the multi-stage build because their runtime binaries may require shared libraries not present in `debian:bookworm-slim`. Dependabot is configured to ignore major Node version bumps to prevent this.

## Security Notice

> **Do not commit secrets to the repository.**
> The `GENIEACS_UI_JWT_SECRET` in docker-compose.yml is a placeholder — always change it in production.
> MongoDB authentication is disabled by default for development convenience — enable it for production.
> Use environment variables or Kubernetes Secrets for all credentials.

---

*Generated by [LynxPrompt](https://lynxprompt.com) CLI*

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

## Where the tracker syncs

This repo is public, so its tracker syncs only to the private Dolt remote named by `sync.remote` in `.beads/config.yaml` (`giteaer/genieacs-container-beads` on Gitea). The block above says sync uses "your git remote". Here that never means this GitHub repo. Don't add it as a Dolt remote and don't push `refs/dolt/*` to it.
