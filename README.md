<p align="center">
  <img src="https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docs/images/banner.svg" alt="GenieACS Container banner" width="900"/>
</p>

<h1 align="center">GenieACS Container</h1>

<p align="center">
  <a href="https://github.com/GeiserX/genieacs-container/releases"><img src="https://img.shields.io/github/v/release/GeiserX/genieacs-container?style=flat-square" alt="Release"></a>
  <a href="https://github.com/GeiserX/genieacs-container/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/GeiserX/genieacs-container/ci.yml?style=flat-square&logo=github&label=CI" alt="CI"></a>
  <a href="https://github.com/GeiserX/genieacs-container/blob/main/LICENSE"><img src="https://img.shields.io/github/license/GeiserX/genieacs-container?style=flat-square" alt="License"></a>
  <a href="https://hub.docker.com/r/drumsergio/genieacs"><img src="https://img.shields.io/docker/pulls/drumsergio/genieacs?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <a href="https://github.com/GeiserX/genieacs-container/stargazers"><img src="https://img.shields.io/github/stars/GeiserX/genieacs-container?style=flat-square&logo=github" alt="GitHub Stars"></a>
</p>

<p align="center">
  <strong>Production-ready Docker containers and deployment tools for <a href="https://genieacs.com">GenieACS</a>, an open-source TR-069 ACS.</strong>
</p>

## Features

- Docker images for GenieACS v1.2.16.0, for amd64 and arm64.
- A Helm chart for Kubernetes, released automatically by GitHub Actions.
- Runs as a non-root user, with security contexts set in the chart.
- Health checks and monitoring support.
- A Compose stack with MongoDB, plus optional simulator (`--profile testing`) and MCP server (`--profile mcp`) services.
- The chart supports Ingress or Gateway API `httpRoute`, and an external MongoDB whose connection string comes from a Kubernetes Secret.

## Quick start

```bash
docker compose up -d
```

This starts GenieACS and MongoDB; open the UI at http://localhost:3000. For Kubernetes:

```bash
helm repo add genieacs https://geiserx.github.io/genieacs-container
helm install genieacs genieacs/genieacs --namespace genieacs --create-namespace --set env.GENIEACS_UI_JWT_SECRET=your-secret-here
```

## Documentation

- [Installation](https://github.com/GeiserX/genieacs-container/blob/main/docs/installation.md): Docker Compose, `docker run`, Helm (bundled, external or Secret-sourced MongoDB), Helmfile, chart values
- [Configuration](https://github.com/GeiserX/genieacs-container/blob/main/docs/configuration.md): ports, volumes, environment variables, security
- [Troubleshooting](https://github.com/GeiserX/genieacs-container/blob/main/docs/troubleshooting.md)
- [Development](https://github.com/GeiserX/genieacs-container/blob/main/docs/development.md): building the image and contributing
- [GenieACS ecosystem](https://github.com/GeiserX/genieacs-container/blob/main/docs/ecosystem.md): the related Ansible, MCP, Home Assistant, n8n and ISP tools

## Related projects

[genieacs-ansible](https://github.com/GeiserX/genieacs-ansible), [genieacs-mcp](https://github.com/GeiserX/genieacs-mcp), [genieacs-ha](https://github.com/GeiserX/genieacs-ha), [n8n-nodes-genieacs](https://github.com/GeiserX/n8n-nodes-genieacs), [genieacs-services](https://github.com/GeiserX/genieacs-services), [genieacs-sim-container](https://github.com/GeiserX/genieacs-sim-container).

## License

This repository (the Dockerfile, Helm chart and scripts) is licensed under GPL-3.0-or-later; see [LICENSE](https://github.com/GeiserX/genieacs-container/blob/main/LICENSE). GenieACS itself, which the image packages, is licensed under [AGPL-3.0](https://github.com/genieacs/genieacs/blob/master/LICENSE).
