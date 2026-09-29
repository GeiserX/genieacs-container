# Configuration

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 7547 | CWMP | TR-069 ACS port for device communication |
| 7557 | NBI | Northbound Interface API |
| 7567 | FS | File Server for firmware/configuration files |
| 3000 | UI | Web-based user interface |

## Volumes

- `/opt/genieacs/ext`: Extension scripts directory
- `/var/log/genieacs`: Log files directory

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GENIEACS_MONGODB_CONNECTION_URL` | MongoDB connection string | Auto-configured when `mongodb.enabled=true` |
| `GENIEACS_UI_JWT_SECRET` | JWT secret for UI authentication | `changeme` |
| `GENIEACS_EXT_DIR` | Extension scripts directory | `/opt/genieacs/ext` |
| `GENIEACS_CWMP_ACCESS_LOG_FILE` | CWMP access log path | `/var/log/genieacs/genieacs-cwmp-access.log` |
| `GENIEACS_NBI_ACCESS_LOG_FILE` | NBI access log path | `/var/log/genieacs/genieacs-nbi-access.log` |
| `GENIEACS_FS_ACCESS_LOG_FILE` | FS access log path | `/var/log/genieacs/genieacs-fs-access.log` |
| `GENIEACS_UI_ACCESS_LOG_FILE` | UI access log path | `/var/log/genieacs/genieacs-ui-access.log` |
| `GENIEACS_DEBUG_FILE` | Debug log path | `/var/log/genieacs/genieacs-debug.yaml` |

The Helm chart options are in [Getting started](getting-started.md#chart-configuration).

## Security considerations

- The container starts as root so it can run cron, then `gosu` drops the GenieACS processes to the unprivileged `genieacs` user, uid 999
- In the Helm chart the pod runs as root (`runAsUser: 0`) for the same reason, with every capability dropped except `SETUID` and `SETGID`
- Default JWT secret should be changed in production
- Use `envFrom` or `extraEnvVars` to inject secrets from Kubernetes Secrets instead of hardcoding in `values.yaml`
- MongoDB authentication should be enabled for production deployments
