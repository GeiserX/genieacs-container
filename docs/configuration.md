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

The Helm chart options are in [Installation](installation.md#chart-configuration).

## Security considerations

- The container runs as a non-root user (`genieacs`)
- Security contexts are configured in the Helm chart
- Default JWT secret should be changed in production
- Use `envFrom` or `extraEnvVars` to inject secrets from Kubernetes Secrets instead of hardcoding in `values.yaml`
- MongoDB authentication should be enabled for production deployments
