# genieacs-container

![genieacs-container](<https://geiserx.github.io/genieacs-container/images/banner.svg>)

[![Docker Pulls](<https://img.shields.io/docker/pulls/drumsergio/genieacs?style=flat-square&amp;logo=docker>)](<https://hub.docker.com/r/drumsergio/genieacs>) [![GitHub Stars](<https://img.shields.io/github/stars/GeiserX/genieacs-container?style=flat-square&amp;logo=github>)](<https://github.com/GeiserX/genieacs-container/stargazers>) [![Release](<https://img.shields.io/github/v/release/GeiserX/genieacs-container?style=flat-square>)](<https://github.com/GeiserX/genieacs-container/releases>) [![License: GPL-3.0](<https://img.shields.io/github/license/GeiserX/genieacs-container?style=flat-square>)](<https://github.com/GeiserX/genieacs-container/blob/main/LICENSE>) [![Artifact Hub](<https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/genieacs&amp;style=flat-square>)](<https://artifacthub.io/packages/helm/genieacs/genieacs>)

---

**genieacs-container** is a Docker image and a Helm chart for [GenieACS](<https://genieacs.com>), the open-source TR-069 ACS that manages routers, ONTs and other CPE devices. GenieACS itself ships no container. This image runs its four services in one container, for amd64 and arm64, with MongoDB beside it: on one host with [Docker Compose](<https://geiserx.github.io/genieacs-container/getting-started/#docker-compose>), or on Kubernetes with the [Helm chart](<https://geiserx.github.io/genieacs-container/getting-started/#kubernetes-with-helm>). It packages GenieACS 1.2.16 and does not change it.

This address is also the Helm chart repository: `helm repo add genieacs https://geiserx.github.io/genieacs-container`.

- **[Run with Docker Compose](<https://geiserx.github.io/genieacs-container/getting-started/index.md>)**

  ---

  One file, `docker compose up -d`, and the GenieACS console is on port 3000 in about a minute.
- **[Your first device](<https://geiserx.github.io/genieacs-container/first-device/index.md>)**

  ---

  Point a CPE, or the bundled simulator, at port 7547 and watch it appear under Devices.
- **[Usage](<https://geiserx.github.io/genieacs-container/usage/index.md>)**

  ---

  The four services, the simulator and MCP profiles, extension scripts and the logs.
- **[Configuration](<https://geiserx.github.io/genieacs-container/configuration/index.md>)**

  ---

  Every port, volume and environment variable, and the chart values that matter.

## What it looks like

The console is upstream GenieACS 1.2.16, served by image `1.2.16.6`. The devices in these screenshots are the [bundled simulator](<https://geiserx.github.io/genieacs-container/first-device/#the-simulator>) (`--profile testing`), so you can see the same thing without hardware.

![The GenieACS Devices list: six simulated CPEs with serial number, product class, software version, IP, SSID, last inform and tags, and the filter bar above them](<https://geiserx.github.io/genieacs-container/images/screenshots/devices.png>)

[![The Overview page with the Online status chart: six devices online now](<https://geiserx.github.io/genieacs-container/images/screenshots/overview.png>)](<https://geiserx.github.io/genieacs-container/images/screenshots/overview.png>)

Overview: who is online

[![One device's page: last inform, serial number, product class, software version, MAC, IP, WLAN SSID, the LAN hosts table and the start of the parameter list](<https://geiserx.github.io/genieacs-container/images/screenshots/device.png>)](<https://geiserx.github.io/genieacs-container/images/screenshots/device.png>)

One device, every parameter

[![The Presets page under Admin: the bootstrap, default and inform presets plus one that targets a tag](<https://geiserx.github.io/genieacs-container/images/screenshots/presets.png>)](<https://geiserx.github.io/genieacs-container/images/screenshots/presets.png>)

Presets: configuration for many devices

[![The Files page under Admin with one firmware image uploaded, showing its type, OUI, product class and version](<https://geiserx.github.io/genieacs-container/images/screenshots/files.png>)](<https://geiserx.github.io/genieacs-container/images/screenshots/files.png>)

Files: firmware devices download

## What is in the image

- The four GenieACS services in one container, under supervisord: `genieacs-cwmp` on 7547 (the ACS URL devices inform to), `genieacs-nbi` on 7557 (the REST API), `genieacs-fs` on 7567 (the file server) and `genieacs-ui` on 3000 (the console).
- GenieACS built from the upstream `v1.2.16` tag on Node 24, on Debian bookworm-slim. The image tag is the upstream version plus a build number: `1.2.16.6`.
- Logs rotated for you: each service writes its own file under `/var/log/genieacs`, and cron runs logrotate daily, 30 days kept, compressed.
- The GenieACS processes run as the unprivileged `genieacs` user (uid 999). Root is used once, to start cron, then dropped with `gosu`.
- MongoDB is not in the image. Compose starts `mongo:9.0.4` beside it; the chart bundles a MongoDB subchart for evaluation or takes your own.

## How it runs

```
flowchart LR
    CPE[Routers, ONTs, the simulator]
    OPS[Scripts, genieacs-mcp, genieacs-ha, genieacs-ansible]
    BR[Browser]
    subgraph image [drumsergio/genieacs]
        CWMP[cwmp :7547]
        NBI[nbi :7557]
        FS[fs :7567]
        UI[ui :3000]
    end
    DB[(MongoDB)]
    CPE -->|inform| CWMP
    CPE -->|download| FS
    OPS --> NBI
    BR --> UI
    CWMP --> DB
    NBI --> DB
    FS --> DB
    UI --> DB
```

- On one host: `docker-compose.yml` runs the image and MongoDB on a private network, exposes the four ports, and keeps two optional services behind profiles: the [simulator](<https://geiserx.github.io/genieacs-container/first-device/#the-simulator>) (`--profile testing`) and the [MCP server](<https://geiserx.github.io/genieacs-container/usage/#optional-compose-services>) (`--profile mcp`).
- On Kubernetes: the chart makes one Deployment, one Service per port, a PersistentVolumeClaim for extension scripts, and, when you turn them on, an Ingress or a Gateway API HTTPRoute for the console and a PodDisruptionBudget. MongoDB comes from the bundled subchart, or from your own instance through `externalMongodb.url` or a Kubernetes Secret. See [Getting started](<https://geiserx.github.io/genieacs-container/getting-started/#kubernetes-with-helm>) and [How it works](<https://geiserx.github.io/genieacs-container/how-it-works/index.md>).
- Health: a Compose healthcheck on port 3000, and liveness and readiness probes in the chart.
- Upgrades: the tag moves when upstream GenieACS moves. Change the pin, `docker compose up -d` or `helm upgrade`, and the data in MongoDB stays. The [changelog](<https://github.com/GeiserX/genieacs-container/blob/main/CHANGELOG.md>) lists every image and chart release.

## What it does not do

- It does not change GenieACS. Provisions, presets, virtual parameters and the UI are upstream's; the [GenieACS documentation](<https://docs.genieacs.com>) covers them.
- It does not terminate TLS. Put a reverse proxy, an Ingress or an HTTPRoute in front of the console and the CWMP port before exposing them.
- The bundled MongoDB subchart is for evaluation. Production runs MongoDB separately and points the chart at it.
- It runs one GenieACS replica by default.

## Security

- Set your own `GENIEACS_UI_JWT_SECRET` with `openssl rand -hex 32`. Neither the compose file nor the chart has a default, and both refuse to start without one; the chart also refuses placeholders such as `changeme` and takes the secret from an existing Kubernetes Secret through `uiJwtSecret.existingSecret`.
- Turn on MongoDB authentication. The compose file has the lines commented; the chart has `mongodb.auth.enabled`.
- In the chart, keep credentials out of `values.yaml`: `externalMongodb.existingSecret` for the connection string, `uiJwtSecret.existingSecret` for the UI secret, `envFrom` or `extraEnvVars` for the rest. See [Configuration](<https://geiserx.github.io/genieacs-container/configuration/#security>).
- The pod starts as root for cron and drops every capability except `SETUID` and `SETGID`; the GenieACS processes run as uid 999.
- To report a security problem, follow the [security policy](<https://github.com/GeiserX/genieacs-container/blob/main/SECURITY.md>) and do not open a public issue.

## Getting help

- If something is broken, read [Troubleshooting](<https://geiserx.github.io/genieacs-container/troubleshooting/index.md>), then open an issue with the details it lists.
- The [changelog](<https://github.com/GeiserX/genieacs-container/blob/main/CHANGELOG.md>) lists what changed between releases.
- For GenieACS itself (provisions, data models, device quirks), the [GenieACS documentation](<https://docs.genieacs.com>) and the [GenieACS forum](<https://forum.genieacs.com>) are the places.
- The Ansible collection, the MCP server, the Home Assistant integration and the simulator are on [Related projects](<https://geiserx.github.io/genieacs-container/related/index.md>).
- To build the image or send a fix, read [Development](<https://geiserx.github.io/genieacs-container/development/index.md>).

## License

genieacs-container (the Dockerfile, the chart and the scripts) is released under the [GPL-3.0-or-later](<https://github.com/GeiserX/genieacs-container/blob/main/LICENSE>) license. GenieACS, which the image packages, is [AGPL-3.0](<https://github.com/genieacs/genieacs/blob/master/LICENSE>).
