# Configuration

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 7547 | CWMP | TR-069 ACS port for device communication |
| 7557 | NBI | Northbound Interface API |
| 7567 | FS | File Server for firmware/configuration files |
| 3000 | UI | Web-based user interface |

## Volumes

- `/opt/genieacs/ext`: extension scripts, mounted from the `ext_volume` volume in Compose and the chart's
  PersistentVolumeClaim.
- `/var/log/genieacs`: the service, access and debug logs; not mounted by default, add a bind mount if you
  want them on the host.

## Environment variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GENIEACS_MONGODB_CONNECTION_URL` | MongoDB connection string | Auto-configured when `mongodb.enabled=true` |
| `GENIEACS_UI_JWT_SECRET` | JWT secret for UI authentication | None, required. Generate one with `openssl rand -hex 32` |
| `GENIEACS_EXT_DIR` | Extension scripts directory | `/opt/genieacs/ext` |
| `GENIEACS_CWMP_ACCESS_LOG_FILE` | CWMP access log path | `/var/log/genieacs/genieacs-cwmp-access.log` |
| `GENIEACS_NBI_ACCESS_LOG_FILE` | NBI access log path | `/var/log/genieacs/genieacs-nbi-access.log` |
| `GENIEACS_FS_ACCESS_LOG_FILE` | FS access log path | `/var/log/genieacs/genieacs-fs-access.log` |
| `GENIEACS_UI_ACCESS_LOG_FILE` | UI access log path | `/var/log/genieacs/genieacs-ui-access.log` |
| `GENIEACS_DEBUG_FILE` | Debug log path | `/var/log/genieacs/genieacs-debug.yaml` |

## Helm chart values

The values people change; every key is in
[values.yaml](https://github.com/GeiserX/genieacs-container/blob/main/charts/genieacs/values.yaml).

```yaml
image:
  repository: drumsergio/genieacs
  tag: "1.2.16.6"

replicaCount: 1

ingress:
  enabled: false
  className: ""  # e.g. "nginx", "traefik"

# Kubernetes Gateway API alternative to `ingress` (requires the
# Gateway API CRDs and a Gateway controller in the cluster).
# Only `parentRefs` is required when enabled.
httpRoute:
  enabled: false
  parentRefs: []
  # - name: my-gateway
  #   namespace: gateway-system
  #   sectionName: https
  hostnames:
    - genieacs.local
  # Optional. Omit to match every request. Besides `path`, each entry
  # accepts `method`, `headers` and `queryParams`.
  matches:
    - path:
        type: PathPrefix
        value: /

# GENIEACS_UI_JWT_SECRET has no default; install and upgrade stop until it is
# set exactly one way. Recommended: a Secret you create, named here.
uiJwtSecret:
  existingSecret: ""   # e.g. genieacs-ui-jwt
  existingSecretKey: GENIEACS_UI_JWT_SECRET

# Or the value itself (it then sits in the Deployment spec):
# env:
#   GENIEACS_UI_JWT_SECRET: <output of openssl rand -hex 32>

# Inject env vars from Kubernetes Secrets/ConfigMaps
envFrom: []
# - secretRef:
#     name: genieacs-secrets

# Env vars with valueFrom (e.g. secretKeyRef)
extraEnvVars: []

# Bitnami MongoDB subchart (deployed alongside GenieACS by default)
mongodb:
  enabled: true
  auth:
    enabled: false
  persistence:
    enabled: true
    size: 8Gi

# Used when mongodb.enabled is false (bring your own MongoDB).
# Set either `url` directly, or `existingSecret` + `secretKey` to
# source the connection string from a Kubernetes Secret (recommended
# for production). If both are set, `existingSecret` takes precedence.
externalMongodb:
  url: ""
  existingSecret: ""
  secretKey: "connectionString"

persistence:
  enabled: true
  size: 5Gi

resources:
  limits:
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 2Gi
```

Unknown keys and wrong types fail at `helm install`; the schema is `charts/genieacs/values.schema.json`.

## Security

- The container starts as root so it can run cron, then `gosu` drops the GenieACS processes to the unprivileged `genieacs` user, uid 999.
- In the Helm chart the pod runs as root (`runAsUser: 0`) for the same reason, with every capability dropped except `SETUID` and `SETGID`.
- `GENIEACS_UI_JWT_SECRET` signs the UI login tokens and has no default. The chart refuses to install or
  upgrade without it, and refuses an empty value or a placeholder such as `changeme`. Keep it in a Secret
  and point `uiJwtSecret.existingSecret` at it, so it never sits in a values file:

  ```bash
  kubectl create secret generic genieacs-ui-jwt --namespace genieacs \
    --from-literal=GENIEACS_UI_JWT_SECRET="$(openssl rand -hex 32)"
  helm upgrade --install genieacs genieacs/genieacs --namespace genieacs \
    --set uiJwtSecret.existingSecret=genieacs-ui-jwt
  ```

  After rotating it in the Secret, run `kubectl -n genieacs rollout restart deployment/genieacs`. A Secret
  listed under `envFrom` does not satisfy the check, because the chart cannot see inside it.
- Use `envFrom` or `extraEnvVars` to inject secrets from Kubernetes Secrets instead of writing them into `values.yaml`.
- Turn on MongoDB authentication for production deployments.
