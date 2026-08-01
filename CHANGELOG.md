# Changelog

All notable changes to this project will be documented in this file.

## Helm Chart [0.5.0] - 2026-08-01

### Added
- **Gateway API `HTTPRoute` support** — the UI service can now be exposed through a Gateway API `HTTPRoute` as an alternative to `Ingress`. Disabled by default; set `httpRoute.enabled=true` and provide `httpRoute.parentRefs`. Supports `annotations`, `parentRefs`, `hostnames`, and path `matches` (#60, thanks @mool)
- **`values.schema.json` validation for `httpRoute`** — enabling the route without `parentRefs` or `matches` now fails at template time with a clear message instead of rendering an unusable resource
- **NOTES.txt lists both access paths** — Ingress and HTTPRoute hosts are now printed separately when either is enabled

## Helm Chart [0.3.4] - 2026-03-31

### Fixed
- **Fix: URL-encode MongoDB passwords with special characters** — when `rootPassword` is set in values, the password is now percent-encoded at template time via `urlquery`, so characters like `@`, `:`, `/`, `%` no longer break the connection URI. Auto-generated passwords (empty `rootPassword`) continue to use runtime `$(VAR)` expansion (Bitnami generates alphanumeric passwords)
- **Fix: Respect `mongodb.fullnameOverride` and `mongodb.auth.existingSecret`** — the chart now resolves the correct MongoDB service name and secret name when users override the subchart's default naming
- **Fix: Remove undeclared `helm-secrets` plugin dependency from examples** — `genieacs-secrets.yaml` moved from Helmfile `secrets:` to `values:` so examples work without plugins

## Helm Chart [0.3.3] - 2026-03-31

### Fixed
- **Helm chart: Authenticated bundled MongoDB now works** — when `mongodb.auth.enabled=true`, the chart auto-constructs an authenticated URI using the root password from the Bitnami subchart secret via Kubernetes env var expansion (#48)
- **docker-compose.yml: Production auth path no longer breaks** — added commented authenticated `GENIEACS_MONGODB_CONNECTION_URL` matching the commented Mongo auth env vars, and cross-referenced the two sections
- **examples/: Updated to current chart** — removed obsolete pre-0.2.0 standalone MongoDB examples; helmfile.yaml now uses chart 0.3.x with bundled subchart; added `genieacs-secrets.yaml` for credential management
- **examples/README.md: Fixed secret name mismatch** — previously told users to create `mongodb-secret` while values expected `genieacs-mongo`
- **README.md: Fixed `master` → `main` references** — logo image URL and LICENSE badge now point to `main` branch
- **Issue templates: Fixed stale Helm chart link** — `tree/master/helm` → `tree/main/charts/genieacs`

## [1.2.16.0] - 2026-03-29

### Changed
- **Upstream GenieACS bumped to v1.2.16** (from v1.2.15)
- Helm chart version bumped to 0.3.2

### Upstream Changes (GenieACS v1.2.16)
- **Fix: Device search component broken in UI** — reverted Mithril.js from v2.3.8 back to v2.2.2 due to unresolved upstream regressions that broke device search and ID parsing
- Removed the v1.2.15 workaround for Mithril double-decoding (no longer needed after revert)

## [1.2.15.0] - 2026-03-27

### Security
- **CRITICAL: Fix RCE vulnerability in `/api/ping` endpoint** — follow-up to CVE-2021-46704; `domainToASCII` bypass allowed shell injection via crafted hostnames. Now uses `execFile` instead of `exec` with proper input validation

### Changed
- **Upstream GenieACS bumped to v1.2.15** (from v1.2.14)
- Helm chart version bumped to 0.3.1

### Upstream Changes (GenieACS v1.2.15)
- **Security: Fix RCE in `/api/ping`** — normalized host with `domainToASCII` before validation, added round-trip check with `domainToUnicode`, switched from `exec` to `execFile`, added `--` separator to ping args. Credit: JuHwiSang
- **Fix: Device IDs with special characters** (`%`) not handled correctly in UI due to Mithril 2.3.8 double-decoding regression — workaround extracts device ID directly from `window.location.hash`
- **Dependency updates** — `koa-compress`, `@types/mithril`, `yaml` patch bumps

## [1.2.14.0] - 2026-03-13

### Changed
- **Upstream GenieACS bumped to v1.2.14** (from v1.2.13)
- Helm chart version bumped to 0.3.0

### Upstream Changes (GenieACS v1.2.14)
- **Fix: Prevent UI crash when a malformed URL is sent to the server** — replaced `koa-static` with a custom `koa-send` wrapper that validates paths and catches errors
- **Fix: Edge-case bugs in `VersionedMap` (de)serialization** — prevents corrupt session state during CWMP parameter revision tracking
- **Fix: Expression evaluation `covers()` function** — corrected logic for contradictions/tautologies affecting preset precondition evaluation
- **Fix: Operator precedence bug in `ui/config-functions.ts`** — bitwise shift vs modulo
- **Dependency modernization** — replaced deprecated `koa-bodyparser`/`koa-router` with `@koa/bodyparser`/`@koa/router`, updated TypeScript to 5.9, esbuild, mithril, and other dependencies

## Helm Chart [0.2.0] - 2026-02-22

### Added
- **MongoDB subchart** (Bitnami 18.6.0) as an optional dependency, enabled by default (#33)
- **`ingressClassName`** support for clusters with multiple ingress controllers (#33)
- **`envFrom`** support for injecting env vars from Kubernetes Secrets/ConfigMaps (#33)
- **`extraEnvVars`** support for env vars with `valueFrom` (e.g. secretKeyRef) (#33)
- **`externalMongodb.url`** for bring-your-own MongoDB deployments (#33)

### Fixed
- Ingress backend now references the correct service name (`*-http`) (#33)
- `appVersion` in Chart.yaml now matches the image tag (1.2.13.4)

### Changed
- Removed redundant `restartPolicy: Always` from Deployment template

### Contributors
- Thanks to [@ggiesen](https://github.com/ggiesen) for reporting and proposing fixes (#33)

## [1.2.13.5] - 2026-02-23

### Fixed
- **Helm chart**: Fixed `capabilities.drop: ALL` preventing supervisord/gosu from switching users - now adds SETUID/SETGID (#34)
- **Helm chart**: Fixed PVC mount masking entrypoint by changing mount from `/opt` to `/opt/genieacs/ext` (#35)
- **Docker image**: Moved entrypoint.sh from `/opt/` to `/usr/local/bin/` to avoid volume mount conflicts

### Changed
- Helm chart version bumped to 0.2.1
- Persistence volume now mounts at `/opt/genieacs/ext` (extensions only) instead of entire `/opt` directory

### Migration Notes (Helm chart 0.2.0 → 0.2.1)

**Breaking change**: The persistence mount path changed from `/opt` to `/opt/genieacs/ext`.

If you have an existing deployment with `persistence.enabled: true` and custom extensions:

1. Backup your extensions:
   ```bash
   kubectl cp <namespace>/<pod-name>:/opt/genieacs/ext ./extensions-backup
   ```
2. Upgrade the Helm chart to 0.2.1
3. Restore extensions to the new mount:
   ```bash
   kubectl cp ./extensions-backup/. <namespace>/<pod-name>:/opt/genieacs/ext/
   ```

**Note**: Chart 0.2.0 with image 1.2.13.4 was non-functional due to #35, so most users won't have data to migrate.

### Contributors
- Thanks to [@ggiesen](https://github.com/ggiesen) for the detailed bug reports (#34, #35)

## [1.2.13.4] - 2026-02-20

### Added
- **Working logrotate** with cron daemon for automatic log rotation
- **gosu** for proper privilege dropping after starting cron
- **entrypoint.sh** to manage cron startup before supervisord

### Changed
- Container now starts as root to run cron, then drops to genieacs via gosu
- Logrotate config updated with `missingok` and `su genieacs genieacs` directives
- Removed unnecessary cron.daily scripts (dpkg, apt-compat) that blocked processing

### Fixed
- Fixed logrotate syntax error with brace expansion (#31)
- Fixed logrotate not running due to missing cron daemon

### Contributors
- Thanks to [@Rocket78](https://github.com/Rocket78) for implementing the working logrotate solution (#32)

## [1.2.13.2] - 2025-12-05

### Added
- **Git CLI** installed in Docker container for enhanced functionality
- **ServiceAccount** support in Helm chart with configurable creation
- **PodSecurityContext** and **SecurityContext** configurations for enhanced security
- **Liveness and Readiness probes** for better health monitoring
- **PodDisruptionBudget** support for high availability deployments
- **NodeSelector, Tolerations, and Affinity** support for advanced scheduling
- **GitHub Actions workflow** for automated Helm chart releases
- **Comprehensive documentation** with improved README and examples
- **Health checks** in docker-compose.yml for both GenieACS and MongoDB
- **Service profiles** in docker-compose.yml for optional services

### Changed
- **Version updated** to 1.2.13.2 (Docker container release)
- **Helm chart version** bumped to 0.1.1
- **Logrotate configuration** moved to `config/` directory for better organization
- **Deployment examples** reorganized from `genieacs-deploy-helmfile/` to `examples/` directory
- **Docker Compose** improved with better restart policies and health checks
- **Helm chart** enhanced with security best practices and production-ready configurations

### Fixed
- Fixed ingress template syntax error
- Fixed PVC template YAML formatting
- Fixed test-connection.yaml to use correct service name and port
- Fixed volumeMounts to only appear when persistence is enabled

### Security
- Container runs as non-root user (genieacs)
- Security contexts configured with least privilege
- Capabilities dropped to minimum required
- Read-only root filesystem option available

