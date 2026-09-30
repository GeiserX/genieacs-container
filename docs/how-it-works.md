# How it works

## What is in the image

`drumsergio/genieacs` is built in three stages (`Dockerfile`):

1. `node:24-bookworm` clones the upstream GenieACS tag (`v1.2.16`), runs `npm ci` and `npm run build`.
2. A helper stage clones [genieacs-services](https://github.com/GeiserX/genieacs-services) at the same
   version for the supervisord configuration.
3. `debian:bookworm-slim` receives the Node runtime and the built GenieACS, plus supervisor, cron,
   logrotate, gosu, wget and ping. It creates the `genieacs` user (uid 999) and the directories
   `/opt/genieacs/ext` and `/var/log/genieacs`.

At start, `entrypoint.sh` starts cron as root, then `exec gosu genieacs supervisord`. supervisord runs
the four services straight from `/opt/genieacs/dist/bin/`; the `GENIEACS_*` variables reach them from the
container's environment:

| Service | Port | Role |
|---|---|---|
| `genieacs-cwmp` | 7547 | The ACS endpoint. Devices inform here and receive their tasks. |
| `genieacs-nbi` | 7557 | The northbound REST API. Scripts, the MCP server, Ansible and Home Assistant use it. |
| `genieacs-fs` | 7567 | The file server devices download firmware and configuration from. |
| `genieacs-ui` | 3000 | The web console. |

All four talk to MongoDB through `GENIEACS_MONGODB_CONNECTION_URL`. Nothing else is stateful: the
extension scripts directory and the logs are the only paths worth a volume.

cron runs logrotate once a day over `/var/log/genieacs/*.log` and `*.yaml`: 30 rotations kept, compressed
from the second day, dated file names.

## Docker Compose

`docker-compose.yml` defines four services on one private network:

- `genieacs`, the image, with the four ports published, a healthcheck on port 3000 (`wget --spider`, 60 s
  start period), the `ext_volume` volume on `/opt/genieacs/ext`, and `depends_on` MongoDB being healthy.
- `mongo`, `mongo:8.0`, with its data and config volumes, port 27017 exposed to the network only, a
  `mongosh` ping healthcheck.
- `genieacs-sim` (profile `testing`), the simulator, started after `genieacs` is healthy.
- `genieacs-mcp` (profile `mcp`), the MCP server on 8080, talking to the NBI with the wizard's default
  login.

## The Helm chart

`charts/genieacs` (0.5.2) creates:

- one Deployment (`replicaCount: 1`) running the image with the `env` block as environment, resource
  requests of 500m CPU and 2Gi memory, a 4Gi memory limit, liveness and readiness probes on port 3000;
- four Services, one per port: `<release>-http` (3000), `<release>-cwmp` (7547), `<release>-nbi` (7557),
  `<release>-fs` (7567), all `ClusterIP` by default;
- a PersistentVolumeClaim (5Gi, `ReadWriteOnce`) mounted at `/opt/genieacs/ext`;
- a ServiceAccount;
- an Ingress or a Gateway API HTTPRoute for the console when enabled, a PodDisruptionBudget when enabled,
  and a `helm test` Pod that connects to the console.

MongoDB comes from the Bitnami subchart (`mongodb.enabled: true`, pinned by image digest) or from your
own instance: `externalMongodb.url`, or `externalMongodb.existingSecret` with the connection string in
a Secret, which the pod reads at start through `valueFrom`. With the subchart and `mongodb.auth.enabled`,
the chart builds the authenticated URI itself.

The pod runs as root (`runAsUser: 0`) so cron can start, drops every capability except `SETUID` and
`SETGID`, and the GenieACS processes run as uid 999 after gosu. `fsGroup: 999` keeps the extension
volume writable.

## Releases

Nothing is built by hand. When `Dockerfile`, `entrypoint.sh` or `config/` change on `main`, `ci.yml`
builds amd64 and arm64, pushes `drumsergio/genieacs:<version>` plus per-arch tags, syncs this README to
Docker Hub and creates the GitHub release. `upstream-check.yml` watches GenieACS for new tags.
`release-chart.yml` packages the chart and updates `index.yaml` on `gh-pages`, the same branch this site
is served from. See [Development](development.md).
