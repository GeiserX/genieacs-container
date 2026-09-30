<p align="center">
  <img src="https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docs/images/banner.svg" alt="genieacs-container" width="100%">
</p>

<p align="center">
  <a href="https://github.com/GeiserX/genieacs-container/releases"><img src="https://img.shields.io/github/v/release/GeiserX/genieacs-container?style=flat-square" alt="Release"></a>
  <a href="https://github.com/GeiserX/genieacs-container/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/GeiserX/genieacs-container/ci.yml?style=flat-square&logo=github&label=CI" alt="CI"></a>
  <a href="https://github.com/GeiserX/genieacs-container/blob/main/LICENSE"><img src="https://img.shields.io/github/license/GeiserX/genieacs-container?style=flat-square" alt="License"></a>
  <a href="https://hub.docker.com/r/drumsergio/genieacs"><img src="https://img.shields.io/docker/pulls/drumsergio/genieacs?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <a href="https://artifacthub.io/packages/helm/genieacs/genieacs"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/genieacs&style=flat-square" alt="Artifact Hub"></a>
</p>

**genieacs-container** is a Docker image and a Helm chart for [GenieACS](https://genieacs.com), the open-source TR-069 ACS that manages routers, ONTs and other CPE devices. GenieACS ships no container of its own; this image runs its four services in one container, for amd64 and arm64, with MongoDB beside it on Docker Compose or on Kubernetes. It packages GenieACS 1.2.16 and does not change it.

<p align="center">
  <img src="https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docs/images/screenshots/devices.png" alt="The GenieACS Devices list with six simulated CPEs: serial number, product class, software version, IP, SSID, last inform and tags" width="100%">
</p>

## Features

- One command gives you a working ACS: the CWMP, NBI, file server and web UI services in one image, MongoDB beside it.
- Current upstream GenieACS (1.2.16), built from source for amd64 and arm64; the tag is the upstream version plus a build number, `1.2.16.6`.
- A simulated CPE one profile away (`--profile testing`), so you can try the console before any hardware informs.
- A Helm chart on Artifact Hub: a bundled MongoDB for evaluation, or your own MongoDB through a Kubernetes Secret for production.
- Ingress or Gateway API HTTPRoute for the console, liveness and readiness probes, an optional PodDisruptionBudget.
- Logs rotated for you: each service writes its own file under `/var/log/genieacs`, kept 30 days, compressed.
- The GenieACS processes run as an unprivileged user; root is used only to start cron.
- An MCP server (`--profile mcp`) that lets an AI assistant work your devices through the NBI.

## Quick start

```bash
# Docker Compose: GenieACS and MongoDB on one host
curl -fsSLO https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docker-compose.yml
docker compose up -d

# Kubernetes: the same image through the Helm chart
helm repo add genieacs https://geiserx.github.io/genieacs-container
helm install genieacs genieacs/genieacs --namespace genieacs --create-namespace \
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
```

Open http://localhost:3000 (on Kubernetes, `kubectl -n genieacs port-forward svc/genieacs-http 3000:3000` first): the first visit runs a setup wizard that creates the `admin` / `admin` login, and your devices inform to `http://<host>:7547/`. Change `GENIEACS_UI_JWT_SECRET` from `changeme` in the compose file before you expose the console. `docker run`, an external MongoDB, Helmfile and the chart values are in [Getting started](https://geiserx.github.io/genieacs-container/getting-started/).

## Documentation

The documentation lives at **[geiserx.github.io/genieacs-container](https://geiserx.github.io/genieacs-container/)**, which is also the Helm chart repository URL.

- [Getting started](https://geiserx.github.io/genieacs-container/getting-started/): Docker Compose, `docker run`, Helm with a bundled, external or Secret-sourced MongoDB, Helmfile
- [Your first device](https://geiserx.github.io/genieacs-container/first-device/): the ACS URL on a CPE, the simulator, what a device looks like once it informs
- [Configuration](https://geiserx.github.io/genieacs-container/configuration/): ports, volumes, environment variables, chart values, security
- [Usage](https://geiserx.github.io/genieacs-container/usage/): the four services, the simulator and MCP profiles, extension scripts, logs
- [How it works](https://geiserx.github.io/genieacs-container/how-it-works/): what is in the image, what the chart creates
- [Troubleshooting](https://geiserx.github.io/genieacs-container/troubleshooting/): the console does not open, a device never appears, MongoDB, reporting a bug
- [Development](https://geiserx.github.io/genieacs-container/development/): building the image, how releases are made
- [Related projects](https://geiserx.github.io/genieacs-container/related/): the Ansible, MCP, Home Assistant, simulator and ISP tools

## Related projects

[genieacs-ansible](https://github.com/GeiserX/genieacs-ansible), [genieacs-mcp](https://github.com/GeiserX/genieacs-mcp), [genieacs-ha](https://github.com/GeiserX/genieacs-ha), [genieacs-services](https://github.com/GeiserX/genieacs-services), [genieacs-sim-container](https://github.com/GeiserX/genieacs-sim-container), and [n8n-nodes-genieacs](https://github.com/GeiserX/n8n-nodes-genieacs) (archived).

## License

[GPL-3.0-or-later](https://github.com/GeiserX/genieacs-container/blob/main/LICENSE) for this repository (the Dockerfile, the chart and the scripts); the GenieACS it packages is [AGPL-3.0](https://github.com/genieacs/genieacs/blob/master/LICENSE).
