# Getting started

Three ways to run it: Docker Compose (GenieACS plus MongoDB on one host), `docker run` against a MongoDB
you already have, or the Helm chart on Kubernetes. The image is `drumsergio/genieacs` on Docker Hub, for
amd64 and arm64.

## Docker Compose

The repository's `docker-compose.yml` runs GenieACS and MongoDB together. Fetch it and start the stack:

```bash
curl -fsSLO https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docker-compose.yml
docker compose up -d
```

This starts GenieACS (ports 7547, 7557, 7567 and 3000) and MongoDB (port 27017, inside the Compose network
only). GenieACS waits for MongoDB to report healthy, so the UI takes about 30 seconds to come up. What
working looks like: http://localhost:3000 opens the GenieACS UI, and `docker compose ps` shows `genieacs`
as `healthy`.

Before you expose it, change `GENIEACS_UI_JWT_SECRET` in the file from `changeme`, and turn on MongoDB
authentication; the commented lines in the file show how.

```bash
# View logs
docker compose logs -f genieacs

# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v
```

Two optional services sit behind profiles:

- `genieacs-sim`: a simulated CPE for testing, `docker compose --profile testing up -d`
- `genieacs-mcp`: the MCP server, `docker compose --profile mcp up -d`

## Docker run

With a MongoDB you already run:

```bash
docker run -d \
  --name genieacs \
  -p 7547:7547 \
  -p 7557:7557 \
  -p 7567:7567 \
  -p 3000:3000 \
  -e GENIEACS_MONGODB_CONNECTION_URL=mongodb://your-mongo-host/genieacs \
  -e GENIEACS_UI_JWT_SECRET=your-secret-here \
  drumsergio/genieacs:1.2.16.6
```

## Kubernetes with Helm

### Using the Official Chart Repository

Add the chart repository:

```bash
helm repo add genieacs https://geiserx.github.io/genieacs-container
helm repo update
```

Install GenieACS:

```bash
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set env.GENIEACS_UI_JWT_SECRET=your-secret-here
```

This deploys GenieACS with a MongoDB instance included by default (no auth). For production with MongoDB auth:

```bash
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=your-secure-password \
  --set env.GENIEACS_UI_JWT_SECRET=your-secret-here
```

To use an external MongoDB (connection string inline):

```bash
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.enabled=false \
  --set externalMongodb.url=mongodb://your-mongo-host/genieacs
```

To use an external MongoDB with the connection string sourced from a
Kubernetes Secret (recommended for production — keeps credentials out
of values files and out of the pod spec):

```bash
kubectl create secret generic genieacs-mongodb \
  --namespace genieacs \
  --from-literal=connectionString="mongodb+srv://user:pass@cluster.example.net/genieacs?retryWrites=true"

helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.enabled=false \
  --set externalMongodb.existingSecret=genieacs-mongodb
```

This pattern integrates with External Secrets Operator, Sealed Secrets,
Vault, and operators that write connection details to a Kubernetes
Secret (MongoDB Atlas Operator, MongoDB Controllers for Kubernetes
(MCK), the Percona Operator).

> **Production note:** The bundled Bitnami MongoDB subchart is intended
> for development and evaluation only. For production deployments, run
> MongoDB separately — managed (MongoDB Atlas), operator-managed
> ([MCK](https://github.com/mongodb/mongodb-kubernetes),
> [Percona Operator for MongoDB](https://github.com/percona/percona-server-mongodb-operator)),
> or self-hosted — and point the chart at it using
> `externalMongodb.existingSecret`.

### Using Helmfile

See the [examples directory](https://github.com/GeiserX/genieacs-container/tree/main/examples) for a complete Helmfile deployment example:

```bash
helmfile -f examples/helmfile.yaml apply
```

### Chart Configuration

Key configuration options in `values.yaml`:

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

env:
  GENIEACS_UI_JWT_SECRET: changeme

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

For complete configuration options, see [charts/genieacs/values.yaml](https://github.com/GeiserX/genieacs-container/blob/main/charts/genieacs/values.yaml).
