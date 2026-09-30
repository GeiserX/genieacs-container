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
as `healthy`. The first visit shows the initialization wizard; accept its defaults, log in as `admin` / `admin`
and change the password. Then [point a device at it](first-device.md).

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

### Install from the chart repository

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
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
```

What working looks like: `kubectl -n genieacs get pods` shows a `genieacs-...` pod and a
`genieacs-mongodb-...` pod, both `Running` and `1/1` within about two minutes (the readiness probe waits
30 s). Port-forward the console with `kubectl -n genieacs port-forward svc/genieacs-http 3000:3000` (the
chart's notes print the same command with local port 8080), then open http://localhost:3000 and run the
wizard. Devices reach the ACS through the `genieacs-cwmp` Service; expose it with a LoadBalancer or a TCP
route before a real CPE can inform.

This deploys GenieACS with a MongoDB instance included by default (no auth). For production with MongoDB auth:

```bash
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=$(openssl rand -base64 24) \
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
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
Kubernetes Secret (recommended for production: keeps credentials out
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

### Helmfile

See the [examples directory](https://github.com/GeiserX/genieacs-container/tree/main/examples) for a complete Helmfile deployment example:

```bash
helmfile -f examples/helmfile.yaml apply
```

### Chart values

The chart values that matter are on [Configuration](configuration.md#helm-chart-values); the full file is
[values.yaml](https://github.com/GeiserX/genieacs-container/blob/main/charts/genieacs/values.yaml).
